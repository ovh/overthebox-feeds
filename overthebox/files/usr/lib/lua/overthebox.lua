-- Copyright 2015 OVH
-- Author: Simon Lelievre <sim@ovh.net>
-- Author: DUPONCHEEL Sebastien <sebastien.duponcheel@ovh.net>
-- Licensed to the public under the ?

local require 	= require
local json	= require "luci.json"
local sys 	= require "luci.sys"

--local http	= require("socket.http")
local https     = require("ssl.https")
local ltn12	= require("ltn12")
local io 	= require("io")
local os 	= require("os")
local string	= require("string")

local print = print
local ipairs, pairs, next, type, tostring, tonumber, error = ipairs, pairs, next, type, tostring, tonumber, error
local table, setmetatable, getmetatable = table, setmetatable, getmetatable

local uci = require("luci.model.uci").cursor()
debug = false
local VERSION = "<VERSION>"
module "overthebox"

api_url = 'https://provisionning.overthebox.net:4443/'

-- Subscribe Sticky to OVH Network as soon as possible a request an unic identifier
function subscribe()
	local lan = iface_info('lan')
	local ip4 = ''
	local ip6 = ''
	if #lan.ipaddrs > 0 then
		ip4 = lan.ipaddrs[1].addr
	end
	if #lan.ip6addrs > 0 then
		ip6 = lan.ip6addrs.addr
	end

	local rcode, res = POST('subscribe', {private_ips = {ip4}})

	-- tprint(res)
	if rcode == 200 then
		uci:set("overthebox", "me", "token", res.token)
		uci:set("overthebox", "me", "device_id", res.device_id)
		uci:save("overthebox")
		uci:commit("overthebox")
	end
	return (rcode == 200), res
end

function status()
        return GET('devices/'.. (uci:get("overthebox", "me", "device_id", {}) or "null").."/actions")
end

function exists(obj, ...)
	for i,v in ipairs(arg) do
		if obj[v] == nil then
	       		return false
		end
	end
	return true
end

function config()
        local rcode, res = GET('devices/'..uci:get("overthebox", "me", "device_id", {}).."/config")
	local ret = {}

	if res.shadow_conf and exists( res.shadow_conf, 'server', 'port', 'lport', 'password', 'method', 'timeout')  then
		uci:set('shadowsocks','proxy','client')
		uci:set('shadowsocks','proxy','server',   res.shadow_conf.server )
		uci:set('shadowsocks','proxy','port',     res.shadow_conf.port)
		uci:set('shadowsocks','proxy','lport',    res.shadow_conf.lport)
		uci:set('shadowsocks','proxy','password', res.shadow_conf.password)
		uci:set('shadowsocks','proxy','method',   res.shadow_conf.method)
		uci:set('shadowsocks','proxy','timeout',  res.shadow_conf.timeout)
		uci:save('shadowsocks')
		uci:commit('shadowsocks')
		table.insert(ret, "shadowsocks")
	end

	if res.vtun_conf and exists( res.vtun_conf, 'server', 'port', 'cipher', 'psk') then
		uci:set('vtund', 'tunnel', 'client')
		uci:set('vtund', 'tunnel', 'server', res.vtun_conf.server )
		uci:set('vtund', 'tunnel', 'port',   res.vtun_conf.port )
		uci:set('vtund', 'tunnel', 'cipher', res.vtun_conf.cipher )
		uci:set('vtund', 'tunnel', 'psk',    res.vtun_conf.psk )
		uci:set('vtund', 'tunnel', 'localip', '10.166.177.2')
		uci:set('vtund', 'tunnel', 'remoteip', '10.166.177.1')
		uci:save('vtund')
		uci:commit('vtund')
		table.insert(ret, "vtund")
	end

	if res.graph_conf and exists( res.graph_conf, 'host', 'write_token') then
		uci:set('scollector','opentsdb', 'client')
		uci:set('scollector', 'opentsdb', 'host', res.graph_conf.host )
		uci:set('scollector', 'opentsdb', 'freq', (res.graph_conf.freq or 300) )
		uci:set('scollector', 'opentsdb', 'wrtoken', res.graph_conf.write_token )
		uci:save('scollector')
		uci:commit('scollector')
		table.insert(ret, 'scollector')
	end

	return true, ret 
end



-- exec command local
function restart(service)
        local ret = run("/etc/init.d/"..service.." restart")
        return true, ret
end

function opkg_update()
	local ret = run("opkg update")
	return true, ret
end

function opkg_upgradable()
        local ret = run("opkg list-upgradable")
	return true, ret
end
function opkg_install(package)
	local ret = run("opkg install "..package)
	return true, ret
end
function upgrade()
	local packages = {'overthebox', 'luci-app-overthebox', 'mwan3otb', 'luci-app-mwan3otb', 'shadowsocks-libev', 'bosun', 'vtund'}
	local retcode = true
	local ret = ""
	for i = 1, #packages do
		-- install package
		local p = packages[i]
		local c, r = opkg_install(p)
		if c == false then
			retcode = false
		end
		ret = ret ..  p .. ": \n" .. r .."\n"
	end
	return retcode, ret
end
function sysupgrade()
	local ret = run("overthebox_last_upgrade -f")
        return true, ret
end
function reboot()
        local ret = run("reboot")
        return true, ret
end


-- action api
function backup_last_action(id)
        uci:set("overthebox", "me", "last_action_id", id)
        uci:save("overthebox")
        uci:commit("overthebox")
end

function get_last_action()
        return uci:get("overthebox", "me", "last_action_id")
end

function flush_action(id)
        uci:delete("overthebox", "me", "last_action_id", id)
        uci:save("overthebox")
        uci:commit("overthebox")
end


function confirm_action(action, status, msg )
	if action == nil then
		return
	end
	local rcode, res = POST('devices/'..uci:get("overthebox", "me", "device_id", {}).."/actions/"..action, {status=status, msg = msg})
end

-- notification events
function notify_boot()
	return notify("BOOT")
end
function notify_shutdown()
        return notify("SHUTDOWN")
end

function notify(event)
	return POST('devices/'..(uci:get("overthebox", "me", "device_id", {}) or "none" ).."/events", {event_name = event, timestamp = os.time()})
end


-- service ovh
function ask_service_confirmation(service)
        uci:set("overthebox", "me", "service", service)
        uci:set("overthebox", "me", "askserviceconfirmation", "1")
	uci:save("overthebox")
        uci:commit("overthebox")
	-- Ask web interface to display activation form
	uci:set("luci", "overthebox", "overthebox")
	uci:set("luci", "overthebox", "activate", "1")
	uci:save("luci")
	uci:commit("luci")

        return true
end
function get_service()
        return GET('devices/'..uci:get("overthebox", "me", "device_id", {}).."/service")
end
function confirm_service(service)
        if service ~= uci:get("overthebox", "me", "service", service) then
                return false, "service does not match"
        end

        local rcode, ret = POST('devices/'..uci:get("overthebox", "me", "device_id", {}).."/service/"..service.."/  confirm", nil )
	if rcode == 200 then
	        uci:delete("overthebox", "me", "askserviceconfirmation")
	        uci:save("overthebox")
	        uci:commit("overthebox")
		-- Ask web interface to enter activated mode
		uci:delete("luci", "overthebox", "activate")
		uci:save("luci")
		uci:commit("luci")
	end
        return (rcode == 200), ret
end


-- base API helpers
function GET(uri)
	return API(uri, "GET", nil)
end

function POST(uri, data)
	return API(uri, "POST", data)
end


function API(uri, method, data)
	url = api_url .. uri

	-- Buildin JSON POST
	local reqbody 	= json.encode(data)
	local respbody 	= {}
	-- Building Request
	local body, code, headers, status = https.request{
		method = method,
		url = url,
		protocol = "tlsv1",
		headers = 
		{
                        ["Content-Type"] = "application/json",
                        ["Content-length"] = reqbody:len(),
			["X-Auth-OVH"] = uci:get("overthebox", "me", "token"),
			["X-Overthebox-Version"] = VERSION
		},
		source = ltn12.source.string(reqbody),
		sink = ltn12.sink.table(respbody),
	}
	-- Parsing response
	-- Parsing json response

	if debug then
		print(method .. " " ..url)
        	print('headers:')
		tprint(headers)
		print('reqbody:' .. reqbody)
		print('body:' .. tostring(table.concat(respbody)))
		print('code:' .. tostring(code))
		print('status:' .. tostring(status))
		print()
	end

	return code, json.decode(table.concat(respbody))
end

-- Mwan conf generator
function update_confmwan()
	local uci = require('luci.model.uci').cursor()
	-- Check if we need to update mwan conf
	local oldmd5 = uci:get("mwan3", "netconfchecksum")
	local newmd5 = string.match(sys.exec("uci -q export network | md5sum"), "[0-9a-f]*")
	if oldmd5 and (oldmd5 == newmd5) then
		log("update_confmwan: no changes !")
		return false, nil
	end
	-- Avoid race condition
	local l = lock("update_confmwan")
	if not l then
		log("Could not acquire lock !")
		return false, nil
	end
	log("Lock on update_confmwan() acquired")
	-- Start main code
	local results={}
	-- clear up mwan config
	uci:delete_all("mwan3","policy")
	uci:delete_all("mwan3","member")
	uci:delete_all("mwan3","interface")
	-- Get trackers IPs
	local interfaces= {}
	local size_interfaces = 0 -- table.getn( does not work....
	local tracking_servers = {}
--	uci:foreach("openvpn", "openvpn",
--		function (section)
--			if section["enabled"] == "1" and section["remote"] ~= nil then
--				table.insert( tracking_servers, section["remote"])
--			end
--		end
--	)
	table.insert( tracking_servers, "213.186.33.99" )
	-- Create a tracker for each mptcp interface
	uci:foreach("network", "interface",
		function (section)
			if section["type"] == "macvlan" then
				if section["multipath"] == "on" then
					if section["gateway"] then
						size_interfaces = size_interfaces + 1
						interfaces[ section[".name"] ] = section
						uci:set("mwan3", section[".name"], "interface")
						uci:set("mwan3", section[".name"], "enabled", "1")
						if next(tracking_servers) then
							uci:set_list("mwan3", section[".name"], "track_ip", tracking_servers)
						end
						uci:set("mwan3", section[".name"], "reliability", "1")
						uci:set("mwan3", section[".name"], "count", "1")
						uci:set("mwan3", section[".name"], "timeout", "2")
						uci:set("mwan3", section[".name"], "interval", "5")
						uci:set("mwan3", section[".name"], "down", "3")
						uci:set("mwan3", section[".name"], "up", "3")
					end
				end
			elseif section[".name"] == "tun0" then
				size_interfaces = size_interfaces + 1
				interfaces["tun0"] = section
			end
		end
	)
	-- Create a tun0 tracker used for non tcp traffic
	uci:set("mwan3", "tun0", "interface")
	uci:set("mwan3", "tun0", "enabled", "1")
--      uci:set_list("mwan3", "tun0", "track_ip", uci:get("vtund", "tunnel", "remoteip"))
        uci:delete("mwan3", "tun0", "track_ip") -- No tracking ip so tun0 is always up
	uci:set("mwan3", "tun0", "reliability", "1")
	uci:set("mwan3", "tun0", "count", "1")
	uci:set("mwan3", "tun0", "timeout", "2")
	uci:set("mwan3", "tun0", "interval", "5")
	uci:set("mwan3", "tun0", "down", "3")
	uci:set("mwan3", "tun0", "up", "3")
	-- Creates mwan3 routing policies
	local first_tun0_policy
	-- generate all members
	local members = {}
	local members_wan = {}
	local list_interf = {}

	for name, interf  in pairs(interfaces) do
		log("Creating mwan policy for " .. name)
		for i=1,size_interfaces do
			local metric = i
			-- build policy name
			local name = interf[".name"].."_m"..metric.."_w1"
			if not members[metric] then
				members[metric] = {}
			end
			if not list_interf[metric] then
				list_interf[metric] =  {}
			end
			if interf[".name"] ~= "tun0" then
				if not members_wan[metric] then
					members_wan[metric] = {}
				end
				table.insert(members_wan[metric], name)
			else
				if first_tun0_policy == nil then
					first_tun0_policy=name
				end
			end
			-- populating ref tables
			table.insert(members[metric], name)
			table.insert(list_interf[metric], interf[".name"])
			--- Creating mwan3 member
			uci:set("mwan3", name, "member")
			uci:set("mwan3", name, "interface",interf[".name"])
			uci:set("mwan3", name, "metric", metric)
			uci:set("mwan3", name, "weight", 1)
		end
	end
	-- generate policies
	log("Creating mwan balanced policy")
	uci:set("mwan3", "balanced", "policy")
	uci:set_list("mwan3", "balanced", "use_member", members_wan[1])
	
	-- all uniq policy
	log("Creating mwan single policy")
	for i=1,#list_interf[1] do
		local name = list_interf[1][i].."_only"
		uci:set("mwan3", name, "policy")
		uci:set_list("mwan3", name, "use_member", members[1][i])
	end

	local seenName = { }
	function generate_route(route)
		local my_members = {}
		local my_interf = {}
		local metric=0

		for i=1,#route do
			metric = metric + 1
			table.insert(my_members, members[metric][route[i]])
			table.insert(my_interf, list_interf[metric][route[i]])
		end

		local name = table.concat(my_interf, "_")
		if #my_interf > 3 then
			name = table.concat(my_interf, "", 1, 3)
		end
		if string.len(name) > 15 then
			name = string.sub(name, 1, 15)
		end
		if seenName[name] == nil then
			log("genrating route of " .. name)
			uci:set("mwan3", name, "policy")
			uci:set_list("mwan3", name, "use_member", my_members)
			seenName[name] = my_members
			if first_tun0_policy == nil and string.find(name, '^tun0*') then
				first_tun0_policy=name
			end
		end
	end

	function table_copy(obj, seen)
		if type(obj) ~= 'table' then 
			return obj 
		end
		if seen and seen[obj] then 
			return seen[obj] 
		end
		local s = seen or {}
		local res = setmetatable({}, getmetatable(obj))
		s[obj] = res
		for k, v in pairs(obj) do
			res[table_copy(k, s)] = table_copy(v, s)
		end
		return res
	end

	function generate_all_routes(tree, possibities, depth)
		if not possibities or #possibities == 0 then
			generate_route(tree)
		else
			for i=1,#possibities do
				local c = table_copy(possibities)
				table.remove(c, i)
				local d = table_copy(tree)
				table.insert(d, possibities[i])
				generate_all_routes( d, c, depth+1)
			end
		end
	end

	local key_members={}
	local n=0

	for k,v in pairs(members) do
		n=n+1
		key_members[n]=k
	end

	-- Setting rule to forward all non tcp traffic to tun0
	if not uci:get("mwan3", "all") then
		uci:set("mwan3", "all", "rule") 
		uci:set("mwan3", "all", "proto", "all")
		uci:set("mwan3", "all", "sticky", "0")
	end
	uci:set("mwan3", "all", "use_policy", "tun0_only")

	if n > 1 then
		if n < 4 then
			generate_all_routes({}, key_members, 0)
		end
		-- Generate failover policy
   		uci:set("mwan3", "failover", "policy")
		local my_members = {}
		table.insert(my_members, first_tun0_policy)
		for i=2,size_interfaces do
			table.insert(my_members, members_wan[i][i - 1])
		end
		uci:set_list("mwan3", "failover", "use_member", my_members)
		uci:set("mwan3", "all", "use_policy", "failover")
	end
	uci:set("mwan3", "netconfchecksum", newmd5)
	uci:save("mwan3")
	uci:commit("mwan3")
	-- Saving net conf md5 and restarting services
	if os.execute("mwan3 status 1>/dev/null 2>/dev/null") == 0 then
		os.execute("nohup /usr/sbin/mwan3 restart &")
		os.execute("nohup /etc/init.d/vtund restart &")
	end
	l:close()
	return result, interfaces
end

function list_running_dhcp()
	local result = {}
	local dhcpd = (sys.exec("cat /var/etc/dnsmasq.conf | grep dhcp-range | cut -c12- | cut -f1 -d','"))
	for line in string.gmatch(dhcpd,'[^\r\n]+') do
		result[line] = true
	end
	return result
end

function create_dhcp_server()
	local result = {}
	local uci = require('luci.model.uci').cursor()
	-- Setup a dhcp server if needed
	local dhcpd_configured = 0
	local dhcpd = list_running_dhcp()
	for i, _ in pairs(dhcpd) do    
		dhcpd_configured = dhcpd_configured + 1
	end
	log( "Count of dhcp configured : " .. dhcpd_configured )
	local minMetricInterface;
	if dhcpd_configured == 0 then
		-- find the interface with the lowest metric
		local minMetric = 255;
		uci:foreach("network", "interface",
			function (section)
				if section["type"] == "macvlan" then
					if section["proto"] == "static" then
						if section[".name"] == "lan" then
							minMetric = 0
							minMetricInterface = section[".name"]
						end
						if section["metric"] ~= nil then
							if tonumber(section["metric"]) < minMetric then
								minMetric = tonumber(section["metric"])
								minMetricInterface = section[".name"]
							end
						end
					end
				end
			end
		)
		if minMetricInterface == nil then
			uci:foreach("network", "interface",
				function (section)
					if section["type"] == "macvlan" then
						if section["proto"] == "static" then
							-- add static only interface => our wans
							log( "Adding DHCP on interface : "..section[".name"] )
							result[ section[".name"] ] = section
							uci:set("dhcp", section[".name"], "dhcp")
							uci:set("dhcp", section[".name"], "interface", section[".name"])
							uci:set("dhcp", section[".name"], "ignore", "0")
							uci:set("dhcp", section[".name"], "force", "1")
							uci:set("dhcp", section[".name"], "start", "50")
							uci:set("dhcp", section[".name"], "limit", "200")
							uci:set("dhcp", section[".name"], "leasetime", "12h")
							uci:set("dhcp", section[".name"], "dhcp_option", "option:router," .. uci:get("interface", section[".name"], 'ipaddr') .. ' ' .. "option:dns-server," .. uci:get("interface", section[".name"], 'ipaddr'))
							sys.exec("echo 'host-record=overthebox.ovh,".. section["ipaddr"]  .."'  >> /etc/dnsmasq.conf")
							dhcpd_configured = dhcpd_configured + 1
							return;
						end
					end
				end
			)
		else
			uci:set("dhcp", minMetricInterface, "dhcp")
			uci:set("dhcp", minMetricInterface, "interface", minMetricInterface)
			uci:set("dhcp", minMetricInterface, "ignore", "0")
			uci:set("dhcp", minMetricInterface, "force", "1")
			uci:set("dhcp", minMetricInterface, "start", "50")
			uci:set("dhcp", minMetricInterface, "limit", "200")
			uci:set("dhcp", minMetricInterface, "leasetime", "12h")
			uci:set("dhcp", minMetricInterface, "dhcp_option", "option:router," .. uci:get("network", minMetricInterface, 'ipaddr') .. ' ' .. "option:dns-server," .. uci:get("network", minMetricInterface, 'ipaddr'))
			sys.exec("echo 'host-record=overthebox.ovh,".. uci:get("network", minMetricInterface, 'ipaddr') .."'  >> /etc/dnsmasq.conf")
			dhcpd_configured = dhcpd_configured + 1
		end
	end
	uci:save("dhcp")
	uci:commit("dhcp")
	-- Cleaning UP lease info for DHCP wizard
	sys.exec("uci delete dhcpdiscovery.if0.lastcheck")
	sys.exec("uci delete dhcpdiscovery.if0.timestamp")
	sys.exec("uci commit dhcpdiscovery")
	-- Reloading Dnsmask
	sys.exec("/etc/init.d/dnsmasq restart")
	if minMetricInterface then
		sys.exec("ifup " .. minMetricInterface)
	end
	return true
end

-- helpers
function lock(name)
        -- Open fd for appending
	local nixio = require('nixio')
        local oflags = nixio.open_flags("wronly", "creat")
        local file, code, msg = nixio.open("/tmp/" .. name, oflags)

        if not file then
        	return file, code, msg
        end

        -- Acquire lock
        local stat, code, msg = file:lock("tlock")
        if not stat then
                return stat, code, msg
        end

        file:seek(0, "end")

        return file
end

function run(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return result
end

function iface_info(iface)
	local result = {}

	local netm = require 'luci.model.network'.init()
	local net = netm:get_network(iface)
	local device = net and net:get_interface()

	if device then
		result.name	= device:shortname()
		result.macaddr	= device:mac()
		result.ipaddrs  = { }
		result.ip6addrs	= { }
		-- populate ipv4 address
		local _, a
		for _, a in ipairs(device:ipaddrs()) do
                	result.ipaddrs[#result.ipaddrs+1] = {
                                        addr      = a:host():string(),
                                        netmask   = a:mask():string(),
                                        prefix    = a:prefix()
                                }
		end
		-- populate ipv6 address
		for _, a in ipairs(device:ip6addrs()) do
			if not a:is6linklocal() then
                        	result.ip6addrs[#result.ip6addrs+1] = {
                                	addr      = a:host():string(),
                                        netmask   = a:mask():string(),
                                        prefix    = a:prefix()
                                }
                        end
		end
	end
	
	return result
end


-- Debug utils
function log(msg)
        if (type(msg) == "table") then
                for key, val in pairs(msg) do
                        log('{')
                        log(key)
                        log(':')
                        log(val)
                        log('}')
        	end
	else
		sys.exec("logger -t luci \"" .. tostring(msg) .. '"')
	end
end


function tprint (tbl, indent)
  if not indent then indent = 0 end
  if not tbl then return end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end


