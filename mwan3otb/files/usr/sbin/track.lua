#! /usr/bin/env lua
-- Copyright 2015 OVH <OverTheBox@ovh.net>
-- Simon Lelievre <simon.lelievre@corp.ovh.com>
-- Sebastien Duponcheel <sebastien.duponcheel@ovh.net>
--
-- This file is part of OverTheBox for OpenWrt.
--
--    OverTheBox is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    OverTheBox is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with OverTheBox.  If not, see <http://www.gnu.org/licenses/>
--
--	Contributor : Jean Labrousse <jlabrous@github.com>
--


local p   = require 'posix'
local sig = require "posix.signal"

local socket    = require("socket")
local http      = require("socket.http")
local ltn12     = require("ltn12")

local json	= require("luci.json")
local libuci	= require("luci.model.uci")
local sys	= require("luci.sys")
local math	= require("math")

math.randomseed(os.time())

local libping	= require("ping")

local method -- ping function bindings
local fallback_method -- fall

http.TIMEOUT = 5

local shaper = {}

sig.signal(sig.SIGUSR1, function ()
	if shaper.interface and shaper.interface ~= "tun0" then
		shaper.reloadtimestamp = os.time()
	end
end)

sig.signal(sig.SIGUSR2, function ()
	if shaper.interface and shaper.interface == "tun0" then
		shaper.reloadtimestamp = os.time()
	end
end)

local function handle_exit()
	p.closelog()
	os.exit();
end

function create_socket(interface, kind)
	local s, fd
	if kind == "stream" then
		s = socket.tcp()
		fd = p.socket(p.AF_INET, p.SOCK_STREAM, 0)
	elseif kind == "datagram" then
		s = socket.udp()
		fd = p.socket(p.AF_INET, p.SOCK_DGRAM, 0)
	else
		log("create_socket: unknown kind")
		return nil
	end
	-- TODO: s:bind with ip
	local ok, err = p.setsockopt(fd, p.SOL_SOCKET, p.SO_BINDTODEVICE, interface)
	if not ok then
		log("create_socket: "..err)
		return nil
	end
	s:setfd(fd)
	return s
end

function dns_query(id, domain)
	local query = {}
	table.insert(query, id)
	table.insert(query, "\1\0") -- Query, RD
	table.insert(query, "\0\1") -- QDCOUNT
	table.insert(query, "\0\0") -- ANCOUNT
	table.insert(query, "\0\0") -- NSCOUNT
	table.insert(query, "\0\0") -- ARCOUNT
	for word in string.gmatch(domain, '([^.]+)') do
		table.insert(query, string.char(#word))
		table.insert(query, word)
	end
	table.insert(query, "\0")   -- end of QNAME
	table.insert(query, "\0\1") -- QTYPE  = A RECORD
	table.insert(query, "\0\1") -- QCLASS = IN
	return table.concat(query)
end

function dns_request(host, interface, timeout, domain, match)
	local s = create_socket(interface, "datagram")
	if not s then
		return false, "dns_request: no socket"
	end
	s:settimeout(timeout)
	local ok, err = s:setpeername(host, "53")
	if not ok then
		s:close()
		return false, "dns_request: "..err
	end
	local id = string.char(math.random(0xFF), math.random(0xFF))
	local ok, err = s:send(dns_query(id, domain))
	if not ok then
		s:close()
		return false, "dns_request: "..err
	end
	local t1 = p.clock_gettime(p.CLOCK_REALTIME)
	local data, err = s:receive()
	local t2 = p.clock_gettime(p.CLOCK_REALTIME)
	s:close()
	if not data then
		return false, "dns_request: "..err
	end
	if id >= data or not string.match(data, match) then
		return false, "dns_request: bad answer"
	end
	local dt = diff_nsec(t1, t2)/1000000
	if dt <= 1 then
		log("dns proxy/cache detected, falling back to ICMP ping method")
		method = fallback_method
		return false, "dns_request: proxy/cache detected"
	end
	return true, dt
end

function socks_request(host, interface, timeout, port)
	local s = create_socket(interface, "stream")
	if not s then
		return false, "socks_request: no socket"
	end
	s:settimeout(timeout)
	local t1 = p.clock_gettime(p.CLOCK_REALTIME)
	local ok, err = s:connect(host, port)
	local t2 = p.clock_gettime(p.CLOCK_REALTIME)
	s:close()
	if not ok then
		return false, "socks_request: "..err
	end
	return true, (diff_nsec(t1, t2)/1000000)
end

function get_public_ip(interface)
	local data = {}
	local status, code, headers = http.request{
		url = "http://ifconfig.ovh",
		create = function() return create_socket(interface, "stream") end,
		sink = ltn12.sink.table(data)
	}
	if status == 1 and code == 200 then
		return table.concat(data):match("(%d+%.%d+%.%d+%.%d+)")
	end
end

function whois_host(interface, host, ip)
	local s = create_socket(interface, "stream")
	if not s then
		return false, "whois_host: no socket"
	end
	s:settimeout(5)
	local ok, err = s:connect(host, "43")
	if ok then
		if host == "whois.arin.net" then
			s:send("n + "..ip.."\r\n")
		else
			s:send(ip.."\r\n")
		end
		local data, err = s:receive("*a")
		s:close()
		if data then
			local refer = data:match("refer:%s+([%w%.]+)")
			if refer then
				return whois_host(interface, refer, ip)
			end
			local netname = data:match("[Nn]et[Nn]ame:%s+([%w%.%-]+)")
			local country = data:match("[Cc]ountry:%s+([%w%.%-]+)")
			if netname and country then
				return true, netname, country
			end
		end
		return false, "whois_host: failed"
	end
	s:close()
	return false, "whois_host: "..err
end

function whois(interface, ip)
	return whois_host(interface, 'whois.iana.org', ip)
end

function diff_nsec(t1, t2)
	local ret = ( t2.tv_sec * 1000000000 + t2.tv_nsec) - (t1.tv_sec * 1000000000 + t1.tv_nsec)
	if ret < 0 then
		print("euhh :", t2.tv_sec, t1.tv_sec, t2.tv_nsec, t1.tv_nsec)
		print(( t2.tv_sec * 1000000000 + t2.tv_nsec), (t1.tv_sec * 1000000000 + t1.tv_nsec))
		print(ret)
		os.exit(-1)
	end
	return ret
end

function log(str)
	p.syslog( p.LOG_NOTICE, opts["i"] .. '.' .. str)
end
function debug(str)
	p.syslog( p.LOG_DEBUG, opts["i"] .. '.' .. str)
end

function hex_dump(buf)
      for byte=1, #buf, 16 do
         local chunk = buf:sub(byte, byte+15)
         log(string.format('%08X  ',byte-1))
         chunk:gsub('.', function (c) log(string.format('%02X ',string.byte(c))) end)
         log(string.rep(' ',3*(16-#chunk)))
         log(' ',chunk:gsub('%c','.'),"\n")
      end
end


local arguments = {
	{"help",        "none",     'h', "bool",   "this help message" },
	{"device",      "required", 'd', "string", "device to check" },
	{"interface",   "required", 'i', "string", "network interface to check"},
	{"method", 	"optional", 'm', "string", "method to check : icmp (default), dns, socks"},
	{"reliability", "required", 'r', "number", "how many success we have to consider the interface up"},
	{"count",       "required", 'c', "number", "count number of test we make"},
	{"timeout",     "required", 't', "number", "request timeout"},
	{"interval",    "required", 'v', "number", "interval between 2 requests"},
	{"down",        "required", 'o', "number", "how many test we failed before consider it's down"},
	{"up",          "required", 'u', "number", "how many test we succeed before consider it's up"}
}

function arguments:usage()
	print("Usage : track.lua arguments host")
	print("Arguments:")
	for k, v in pairs(arguments) do
                if type(v) == "table" then
			print(string.format("  -%s or --%-20s %-6s %s", v[3], v[1], v[4], v[5]))
		end
	end
	os.exit()
end

function arguments:short() 
	local s = ""
	for k, v in pairs(arguments) do
		if type(v) == "table" then
			if v[4] == "bool" then
				s = s .. v[3]
			else
				s = s .. v[3] .. ':'
			end
		end
	end
	return s
end

function arguments:long()
        local s = {}
        for k, v in pairs(arguments) do
                if type(v) == "table" then
			table.insert(s, {v[1], v[2], v[3] })
                end
        end
        return s
end

function arguments:all_required_are_not_here(opt)
	for k, v in pairs(arguments) do
                if type(v) == "table" then
			if v[2] == "required" and  opt[ v[3] ] == nil then
				return false, v[1].." is missing"
			end
                end
        end
        return true
end

p.openlog("track")

opts={}
local last_index = 1
for r, optarg, optind, li in p.getopt (arg, arguments:short(), arguments:long()) do
  if r == '?' then return print  'unrecognized option' end
  last_index = optind
  opts[ r ] = optarg or true
end

servers={}
for i = last_index, #arg do
	if string.find(arg[i], "%d+.%d+.%d+.%d+") then
--		print("track : "..arg[i])
		table.insert(servers, arg[i])
	else
		print("not reconize : "..arg[i])
	end
end

if opts["h"] then
	arguments:usage()
end

local ok, err = arguments:all_required_are_not_here(opts) 
if not ok then
        arguments:usage()
end

if table.getn(servers) == 0 then
	print("no server found")
        arguments:usage()
end

method = function(s) return libping.send_ping(s , opts["i"], tonumber(opts["t"]) * 1000, 4) end
if opts["m"] == "dns" then
	debug("test dns method")
	fallback_method = method
	method = function(s) return dns_request(s, opts["i"], tonumber(opts["t"]), "tracker.overthebox.ovh", "\127\6\8\4") end
elseif opts["m"] == "sock" then
	debug("test sock method")
	fallback_method = method
	method = function(s) return socks_request(s, opts["i"], tonumber(opts["t"]), "1090") end
end

local fn = "/var/run/mwan3track-"..opts["i"]..".pid"
local fd, err = io.open(fn, 'r')
if fd then
	io.input(fd)
	local pid = io.read()
	io.close(fd)
	if pid and tonumber(pid) > 1 then p.kill(pid, sig.SIGTERM) end
end

local fd, err = io.open(fn, 'w')
io.output(fd)
io.write(p.getpid(), "\n")
io.close(fd)

os.execute("mkdir -p /tmp/tracker/if")

local nb_up = tonumber(opts["u"])
local nb_down = tonumber(opts["o"])

local score=nb_up + nb_down
local init_score = score
local host_up_count=0
local lost=0

function run(command)
	debug("execute : " .. command)
	os.execute(command)
--	local handle = io.popen(command)
--	local result = handle:read("*a")
--	handle:close()
end

-- Interface info structure
local interface		= {}
interface.name		= opts["i"]
interface.device	= opts["d"]
interface.wanaddr	= false
interface.whois		= false
interface.country	= false
interface.timestamp	= nil

function updateInterfaceInfos()
	local wanaddr = get_public_ip(interface.name)
	if wanaddr then
		debug("wan address is: " .. wanaddr)
		interface.timestamp = os.time()
		if interface.wanaddr ~= wanaddr then
			interface.wanaddr = wanaddr
			res, interface.whois, interface.country = whois(interface.name, interface.wanaddr)
			if res then
				if interface.whois and interface.country then
					debug("whois of " .. wanaddr .. " is " .. interface.whois .. " and country is ".. interface.country)
				elseif interface.whois then
					debug("whois of " .. wanaddr .. " is " .. interface.whois)
				end
				-- Update uci infos
				local uci = libuci.cursor()
				if interface.name == "tun0" or interface.name == "xtun0" then
					if interface.whois and interface.country then
						uci:set("network", interface.name, "label", string.format('%s-%s', interface.country, interface.whois))
						uci:save("network")
						uci:commit("network")
					elseif interface.whois then
						uci:set("network", interface.name, "label", interface.whois)
						uci:save("network")
						uci:commit("network")
					end
				elseif not uci:get("network", interface.name, "label") then
					uci:set("network", interface.name, "label", interface.whois)
					uci:save("network")
					uci:commit("network")
				end
			end
			return true
		end
	end
	return false
end

-- Circular buffer for ping stats collection
local pingstats 	= {}
pingstats.numvalue 	= 60
pingstats.entries	= 0
pingstats.pos		= 0

function pingstats:push(value)
	pingstats[pingstats.pos] = value
	pingstats.pos = pingstats.pos + 1
	-- 
	if pingstats.pos < pingstats.numvalue then
		pingstats.entries = pingstats.entries + 1
	else
		pingstats.pos = pingstats.pos - pingstats.numvalue
	end
end

function pingstats:avg()
	sum = 0
	if pingstats.entries == 0 then
		return sum
	end
	for index = #pingstats, 1, -1 do
		local item = pingstats[index]
		sum = sum + item
	end
	return sum / #pingstats
end

function pingstats:min()
	min = 10000
        if pingstats.entries == 0 then
                return min
        end
        for index = #pingstats, 1, -1 do
		min = math.min(pingstats[index], min)
        end
        return min
end

function pingstats:getn(index)
	index = math.abs(index)

	if index >= pingstats.numvalue then 
		return 0
	end

	local pos = pingstats.pos - 1 - index
	if pos < 1 then 
		pos = pingstats.numvalue + pos
	end

        return pingstats[pos] or 10000
end

function pingstats:setn(index, value)
        index = math.abs(index)

        if index >= pingstats.numvalue then
                return 0
        end

        local pos = pingstats.pos - 1 - index
        if pos < 1 then
                pos = pingstats.numvalue + pos
        end
	pingstats[pos] = value
end

-- Bandwith stats
local bw_stats	= {}
bw_stats.values = {}
bw_stats.command= "/usr/bin/luci-bwc"
function bw_stats:collect()
	-- run bandwidth monitor
	local handle = io.popen(string.format("%s -i %s", bw_stats.command, interface.name))
	if not handle then return 0 end
	local result = handle:read("*a")
	handle:close()
	-- store rsult in table
	if result then
		bw_stats.values = json.decode("[" .. string.gsub(result, '[\r\n]', '') .. "]")
	end
	return bw_stats.values
end

function bw_stats:avgdownload(timestamp)
        local sum=0
	local count=0

	local mintimestamp
	local maxtimestamp
	local minvalue
	local maxvalue

        for index = #bw_stats.values, 1, -1 do
		if bw_stats.values[index][1] >= timestamp then
			if mintimestamp == nil then
				mintimestamp = bw_stats.values[index][1]
			end
			if maxtimestamp == nil then
				maxtimestamp = bw_stats.values[index][1]
			end
			mintimestamp = math.min(mintimestamp, bw_stats.values[index][1])
			maxtimestamp = math.max(maxtimestamp, bw_stats.values[index][1])
			if minvalue == nil then
				minvalue = bw_stats.values[index][2]
			end
			if maxvalue == nil then
				maxvalue = bw_stats.values[index][2]
			end
			minvalue = math.min(minvalue, bw_stats.values[index][2])
			maxvalue = math.max(maxvalue, bw_stats.values[index][2])

			sum = sum + bw_stats.values[index][2]
			count = count + 1
		end
        end
	if count > 1 and maxvalue > minvalue and maxtimestamp > mintimestamp then
		local value = math.floor((((maxvalue - minvalue) / (maxtimestamp - mintimestamp)) * 8) / 1024)
		bw_stats.maxdownloadvalue = math.max(bw_stats.maxdownloadvalue, value)
	        return value
	else
		return nil
	end
end

function bw_stats:avgupload(timestamp)
    local sum=0
    local count=0

    local mintimestamp
    local maxtimestamp
    local minvalue
    local maxvalue

        for index = #bw_stats.values, 1, -1 do
        if bw_stats.values[index][1] >= timestamp then
            if mintimestamp == nil then
                mintimestamp = bw_stats.values[index][1]
            end
            if maxtimestamp == nil then
                maxtimestamp = bw_stats.values[index][1]
            end
            mintimestamp = math.min(mintimestamp, bw_stats.values[index][1])
            maxtimestamp = math.max(maxtimestamp, bw_stats.values[index][1])
            if minvalue == nil then
                minvalue = bw_stats.values[index][4]
            end
            if maxvalue == nil then
                maxvalue = bw_stats.values[index][4]
            end
            minvalue = math.min(minvalue, bw_stats.values[index][4])
            maxvalue = math.max(maxvalue, bw_stats.values[index][4])

            sum = sum + bw_stats.values[index][4]
            count = count + 1
        end
        end
    if count > 1 and maxvalue > minvalue and maxtimestamp > mintimestamp then
    		local value = math.floor((((maxvalue - minvalue) / (maxtimestamp - mintimestamp)) * 8) / 1024)
		bw_stats.maxuploadvalue = math.max(bw_stats.maxuploadvalue, value)
		return value
    else
        return nil
    end
end

bw_stats.maxdownloadvalue = 512
function bw_stats:maxdownload()
	return bw_stats.maxdownloadvalue
end

bw_stats.maxuploadvalue = 128
function bw_stats:maxupload()
	return bw_stats.maxuploadvalue
end

--------------------------
--      QoS section     --
--------------------------

-- Service API helpers
function POST(uri, data)
	return API(uri, "POST", data)
end
function PUT(uri, data)
	return API(uri, "PUT", data)
end
function DELETE(uri, data)
	return API(uri, "DELETE", data)
end
function API(uri, method, data)
	-- url = "http://api/" .. uri : we do not use the dns "api" beacause of the dnsmasq reloading race condition
	url = "http://169.254.254.1/" .. uri
	-- Buildin JSON POST
	local reqbody   = json.encode(data)
	local respbody  = {}
	-- Building Request
	local body, code, headers, status = http.request{
		method = method,
		url = url,
		protocol = "tlsv1",
		headers = {
			["Content-Type"] = "application/json",
			["Content-length"] = reqbody:len(),
			["X-Auth-OVH"] = libuci.cursor():get("overthebox", "me", "token"),
		},
		source = ltn12.source.string(reqbody),
		sink = ltn12.sink.table(respbody),
	}
	log(method..' api/'..uri..' '..reqbody..' '..code)
	return code, json.decode(table.concat(respbody))
end

-- Initializing Shaping object

(function ()
	local uci = libuci.cursor()
	shaper.interface      = opts["i"]
	shaper.mode           = uci:get("network", shaper.interface, "trafficcontrol") or "off" -- auto, static
	shaper.mindownload    = tonumber(uci:get("network", shaper.interface, "mindownload")) or 512 -- kbit/s
	shaper.minupload      = tonumber(uci:get("network", shaper.interface, "minupload")) or 128 -- kbit/s
	shaper.qostimeout     = tonumber(uci:get("network", shaper.interface, "qostimeout")) or 30 -- min
	shaper.pingdelta      = tonumber(uci:get("network", shaper.interface, "pingdelta")) or 100 -- ms
	shaper.bandwidthdelta = tonumber(uci:get("network", shaper.interface, "bandwidthdelta")) or 100 -- kbit/s
	shaper.ratefactor     = tonumber(uci:get("network", shaper.interface, "ratefactor")) or 1 -- 0.9 mean 90%
	-- Shaper timers
	shaper.reloadtimestamp    = 0   -- Time when signal to (re)load qos was received
	shaper.qostimestam        = nil -- Time of when QoS was enabled, nil mean that QoS is disabled
	shaper.losttimestamp      = nil -- Time when we lost the first ping
	shaper.congestedtimestamp = nil -- Time when we detect a link congestion
end)()

-- Shaper functions
function shaper:pushPing(lat)
	if lat == false then
		lat = 1000
		if shaper.interface ~= "tun0" then
			if shaper.losttimestamp == nil then
				shaper.losttimestamp = os.time()
			end
			bw_stats:collect()
		end
	else
		-- When tun0 started (or is notified about a new tracker), notify all trackers to start their QoS
		if shaper.interface == "tun0" then
			if shaper.qostimestamp == nil or (shaper.reloadtimestamp > shaper.qostimestamp) then
				shaper:enableQos()
				run('pkill -USR1 -f "mwan3track -i"')
			end
		-- Notify tun0 that a new tracker as started pinging
		elseif shaper.reloadtimestamp == 0 then
			run('pkill -USR2 -f "mwan3track -i tun0"')
		end
	end
	pingstats:push(lat)
	-- QoS manager
	if shaper.mode ~= "off" and (lat > (pingstats:min() + shaper.pingdelta)) then
		if shaper.congestedtimestamp == nil then
			debug("Starting bandwidth stats collector on " .. shaper.interface)
			shaper.congestedtimestamp = os.time()
		end
	        bw_stats:collect()
	end
end

function shaper:isCongested()
	if pingstats:getn(0) > (min + shaper.pingdelta) and pingstats:getn(-1) > (min + shaper.pingdelta) and pingstats:getn(-2) > (min + shaper.pingdelta) then
		return true
	else
		return false
	end
end

function shaper:update()
	-- A reload of qos has been asked
	if shaper.reloadtimestamp and ((shaper.qostimestamp == nil) or (shaper.reloadtimestamp > shaper.qostimestamp)) then
		-- Reload uci
		local uci = libuci.cursor()
		local newMode = uci:get("network", shaper.interface, "trafficcontrol") or "off" -- auto, static
		-- QoS mode has changed
		if shaper.mode ~= newMode then
			shaper.mode = newMode
			shaper:disableQos()
		end
		-- Update values 
		shaper.mindownload	= tonumber(uci:get("network", shaper.interface, "mindownload")) or 512 -- kbit/s
		shaper.minupload	= tonumber(uci:get("network", shaper.interface, "minupload")) or 128 -- kbit/s
		shaper.qostimeout	= tonumber(uci:get("network", shaper.interface, "qostimeout")) or 30 -- min
		shaper.pingdelta	= tonumber(uci:get("network", shaper.interface, "pingdelta")) or 100 -- ms
		shaper.bandwidthdelta	= tonumber(uci:get("network", shaper.interface, "bandwidthdelta")) or 100 -- kbit/s
		shaper.ratefactor	= tonumber(uci:get("network", shaper.interface, "ratefactor")) or 1 -- 0.9 mean 90%
	end
	-- 
	if shaper.mode == "auto" then
		local uci = libuci.cursor()
		if uci:get("network", shaper.interface, "upload") then
			shaper.upload = tonumber(uci:get("network", shaper.interface, "upload"))
		end
		if shaper.qostimestamp and shaper.qostimeout and (os.time() > (shaper.qostimestamp + shaper.qostimeout * 60)) then
			log(string.format("disabling download QoS after %s min", shaper.qostimeout))
			shaper:disableQos()
		end
		if shaper:isCongested() then
			local download = bw_stats:avgdownload(shaper.congestedtimestamp - 2)
			local upload   = bw_stats:avgupload(shaper.congestedtimestamp - 2)
			log("avg rate since ".. shaper.congestedtimestamp .." is " .. download .. " kbit/s down and " .. upload .." kbit/s up")
			-- upload congestion detected
			if upload > download then
				if uci:get("network", shaper.interface, "upload") then
					shaper.upload = tonumber(uci:get("network", shaper.interface, "upload"))
				else
					shaper.upload = math.floor(upload * shaper.ratefactor)
					if shaper.download ~= nil then
						shaper:enableQos()
					end
				end
			else
				shaper.download = math.floor(download * shaper.ratefactor)
				shaper:enableQos()
			end
		end
	elseif shaper.mode == "static" then
		local uci = libuci.cursor()
		if shaper.qostimestamp == nil or (shaper.reloadtimestamp > shaper.qostimestamp) then
			shaper.upload	= tonumber(uci:get("network", shaper.interface, "upload"))
			shaper.download = tonumber(uci:get("network", shaper.interface, "download"))
			shaper:enableQos()
		end
	end
end

function shaper:enableQos()
	if shaper.qostimestamp == nil or (shaper.reloadtimestamp > shaper.qostimestamp) then
		shaper.qostimestamp = os.time()
		if shaper.interface == "tun0" then
			log(string.format("Reloading DSCP rules", shaper.interface))
			run(string.format("/etc/init.d/dscp reload %s", shaper.interface))
		else
			log(string.format("Enabling QoS on interface %s", shaper.interface))
			run(string.format("/usr/lib/qos/run.sh start %s", shaper.interface))
		end
		shaper:sendQosToApi()
	end
end

function shaper:disableQos()
	if shaper.qostimestamp then
		if shaper.interface ~= "tun0" then
			log(string.format("Disabling QoS on interface %s", shaper.interface))
			local uci	= libuci.cursor()
			local mptcp	= uci:get("network", shaper.interface, "multipath")
			local metric	= uci:get("network", shaper.interface, "metric")
			if mptcp == "on" or mptcp == "master" or mptcp == "backup" or mptcp == "handover" then
				if metric then
					local rcode, res = DELETE("qos/"..metric, {})
				end
			end
			run(string.format("/usr/lib/qos/run.sh stop %s", shaper.interface))
		end
		shaper.qostimestamp=nil
		shaper.congestedtimestamp=nil
	end
end

function shaper:sendQosToApi()
	local uci   = libuci.cursor()
	local mptcp = uci:get("network", shaper.interface, "multipath")
	if shaper.interface == "tun0" then
		local commitid = tostring(os.time())
		uci:foreach("dscp", "classify",
			function (dscp)
				if dscp['direction'] == "download" or dscp['direction'] == "both" then
					if commitid then
						local rcode, res = POST("dscp/"..commitid, {
							proto 		= dscp["proto"],
							src_ip		= dscp["src_ip"],
							src_port	= dscp["src_port"],
							dest_ip		= dscp["dest_ip"],
							dest_port	= dscp["dest_port"],
							dpi		= dscp["dpi"],
							class		= dscp["class"]
						})
						-- On error, nil commid to kill dscp transaction
						if tostring(rcode):gmatch("200") == nil then
							commitid = nil;
						end
					end
				end
			end
		)
		if commitid then
			local rcode, res = POST("dscp/"..commitid.."/commit")
			if tostring(rcode):gmatch("200") then
				shaper.qostimestamp = os.time()
			else
				shaper.reloadtimestamp = os.time()
			end
		else
			shaper.reloadtimestamp = os.time()
		end
	elseif mptcp == "on" or mptcp == "master" or mptcp == "backup" or mptcp == "handover" then
		local rcode, res = PUT("qos", {
			interface	= shaper.interface,
			metric		= uci:get("network", shaper.interface, "metric"),
			wan_ip		= interface.wanaddr or get_public_ip(shaper.interface),
			downlink	= tostring(shaper.download),
			uplink		= tostring(shaper.upload)
		})
		if tostring(rcode):gmatch("200") then
			shaper.qostimestamp = os.time()
		else
			shaper.reloadtimestamp = os.time()
		end
	end
end

function write_stats()
	local result = {}
	result[interface.name] = {}
	result[interface.name].wanaddr = interface.wanaddr
	result[interface.name].whois = interface.whois
	result[interface.name].country = interface.country
	-- Ping stats
	if pingstats then
		result[interface.name].minping = pingstats:min()
		result[interface.name].curping = pingstats:getn(0)
		result[interface.name].avgping = pingstats:avg()
	end
	-- QoS status
	if shaper then
		result[interface.name].congestedtimestamp	= shaper.congestedtimestamp
		result[interface.name].qostimestamp		= shaper.qostimestamp
		result[interface.name].reloadtimestamp		= shaper.reloadtimestamp
		result[interface.name].losttimestamp		= shaper.losttimestamp
		result[interface.name].upload			= shaper.upload
		result[interface.name].download			= shaper.download
		result[interface.name].qosmode			= shaper.mode
	end
	-- write file
	local file = io.open( string.format("/tmp/tracker/if/%s", interface.name), "w" )
	if file then
		file:write(json.encode(result))
		file:close()
	end
end

--
-- Main loop
--
while true do

	for i = 1, #servers do
		local ok, msg = method( servers[i] )
		if ok then
			host_up_count = host_up_count + 1

			lat = tonumber(msg)
			-- Check public ip every 900 sec and reload QoS if public ip change
			if interface.timestamp == nil or (os.time() > interface.timestamp + 900) then
				if updateInterfaceInfos() and shaper.qostimestamp then
					shaper.reloadtimestamp = os.time()
				end
			end
			-- Update shaper
			shaper:pushPing(lat)
			local min = pingstats:min()
			debug("check: "..servers[i].. " OK " .. lat .. "ms" .. " was " .. pingstats:getn(-1) .. " " .. pingstats:getn(-2) .. " " .. pingstats:getn(-3) .. " (" .. tostring(min) .. " min)")
		else
			lost = lost + 1

			shaper:pushPing(false)
			debug("check: "..servers[i].." failed was " .. pingstats:getn(-1) .. " " .. pingstats:getn(-2) .. " " .. pingstats:getn(-3))
		end
		write_stats()
		shaper:update()
	end

	if host_up_count < tonumber( opts["r"]) then
		score = score - 1
		if score < nb_up then score = 0 end 
		if score == nb_up then
			if shaper.losttimestamp == nil then
				log(string.format("Interface %s (%s) is offline (losttimestamp is nil)", opts["i"], opts["d"]))
				-- exec hotplug iface
				run(string.format("/usr/sbin/track.sh ifdown %s %s", opts["i"], opts["d"]))
				-- Set interface info as obsolet
				interface.timestamp = nil
				-- clear QoS on interface down
				if shaper.mode ~= "off" then
					shaper:disableQos()
				end
				score = 0
			else
				local dlspeed = bw_stats:avgdownload(shaper.losttimestamp - 2)
				local upspeed = bw_stats:avgupload(shaper.losttimestamp - 2)
				if (dlspeed ~= nil and dlspeed < shaper.mindownload) and (upspeed ~= nil and upspeed < shaper.minupload) then
					log(string.format("Interface %s (%s) is offline (unsuficient bandwith to keep alive)", opts["i"], opts["d"]))
					-- exec hotplug iface
					run(string.format("/usr/sbin/track.sh ifdown %s %s", opts["i"], opts["d"]))
					-- clear QoS on interface down
					if shaper.mode ~= "off" then
						shaper:disableQos()
					end
					shaper.losttimestamp = nil

					score = 0
				else
					if dlspeed ~= nil or upspeed ~= nil then
						log(string.format("Interface %s (%s) lost his tracker but we still have some traffic (up %s kbit/s, dn %s kbit/s)", opts["i"], opts["d"], dlspeed, upspeed))
						shaper.losttimestamp = os.time()
					else
						log(string.format("Interface %s (%s) lost his tracker (no bandwith stats yet)", opts["i"], opts["d"]))
					end

					lost = 0
					score = score + 1
				end
			end
		end
	else
		if score < init_score and lost > 0 then
			shaper.losttimestamp = nil
			log(string.format("Lost %d ping(s) on interface %s (%s)", (lost * opts["c"]), opts["i"], opts["d"]))
		end

		score = score + 1
		lost = 0

		if score > nb_up then score = init_score end
		if score == nb_up then
			log(string.format("Interface %s (%s) is online", opts["i"],    opts["d"]))
			-- exec hotplug iface	
			run(string.format("/usr/sbin/track.sh ifup %s %s", opts["i"], opts["d"]))
		end
	end

	host_up_count=0
	-- sleep interval asked
	p.sleep( opts["v"] )
end
