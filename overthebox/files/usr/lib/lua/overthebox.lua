-- Copyright 2015 OVH
-- Author: Simon Lelievre <sim@ovh.net>
-- Author: DUPONCHEEL Sebastien <sebastien.duponcheel@ovh.net>
-- Licensed to the public under the ?

local require = require
local json	= require "luci.json"

local http	= require("socket.http")
local ltn12	= require("ltn12")
local io 	= require("io")
local os 	= require("os")
local string	= require("string")

local print = print
local ipairs, pairs, next, type, tostring, error = ipairs, pairs, next, type, tostring, error
local table = table

local uci = require("luci.model.uci").cursor()
local debug = false
local VERSION = "0.01a"
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
	end
	return rcode, res
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
		uci:set('shadowsocksdev','proxy','client')
		uci:set('shadowsocksdev','proxy','server',   res.shadow_conf.server )
		uci:set('shadowsocksdev','proxy','port',     res.shadow_conf.port)
		uci:set('shadowsocksdev','proxy','lport',    res.shadow_conf.lport)
		uci:set('shadowsocksdev','proxy','password', res.shadow_conf.password)
		uci:set('shadowsocksdev','proxy','method',   res.shadow_conf.method)
		uci:set('shadowsocksdev','proxy','timeout',  res.shadow_conf.timeout)
		uci:save('shadowsocksdev')
		table.insert(ret, "shadowsock")
	end

	if res.vtun_conf and exists( res.vtun_conf, 'server', 'port', 'cipher', 'psk') then
		uci:set('vtunddev', 'tunnel', 'client')
		uci:set('vtunddev', 'tunnel', 'server', res.vtun_conf.server )
		uci:set('vtunddev', 'tunnel', 'port',   res.vtun_conf.port )
		uci:set('vtunddev', 'tunnel', 'cipher', res.vtun_conf.cipher )
		uci:set('vtunddev', 'tunnel', 'psk',    res.vtun_conf.psk )
		uci:set('vtunddev', 'tunnel', 'localip', '10.166.177.2')
		uci:set('vtunddev', 'tunnel', 'remoteip', '10.166.177.1')
		uci:save('vtunddev')
		table.insert(ret, "vtund")
	end

	if res.graph_conf and exists( res.graph_conf, 'host', 'write_token') then
		uci:set('scollectordev','opentsdb', 'client')
		uci:set('scollectordev', 'opentsdb', 'host', res.graph_conf.host )
		uci:set('scollectordev', 'opentsdb', 'freq', (res.graph_conf.freq or 300) )
		uci:set('scollectordev', 'opentsdb', 'wrtoken', res.graph_conf.write_token )
		uci:save('scollectordev')
		table.insert(ret, 'scollector')
	end

	return true, ret 
end



-- exec command local
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
	local packages = {'overthebox', 'overthebox-luci', 'mwan3otb', 'mwan3otb-luci', 'shadowsocks-libev', 'bosun', 'vtund'}
	local retcode = 0
	local ret = {}
	for i = 1, #packages do
		-- install package
		local p = packages[i]
		local c, r = opkg_install(p)
		if c > retcode then -- BUG
			retcode = c
		end
		table.insert(ret, p .. ": " .. r)
	end
	return retcode, ret
end
function sysupgrade()
	local ret = run("overthebox_last_upgrade -f")
        return true, ret
end

-- action api
function confirm_action(action, status, msg )
	local str_status
	if status == true then
		str_status = "done"
	elseif status == false then
		str_status = "error"
	else
		str_status = status  -- if got other than a boolean
	end
	local rcode, res = POST('devices/'..uci:get("overthebox", "me", "device_id", {}).."/actions/"..action, {status=str_status, msg = msg})
end

-- notification events
function notify_boot()
	return notify("BOOT")
end
function notify_shutdown()
        return notify("SHUTDOWN")
end

function notify(event)
	return POST('devices/'..uci:get("overthebox", "me", "device_id", {}).."/events", {event_name = event, timestamp = os.time()})
end


-- service ovh
function get_service()
	return GET('devices/'..uci:get("overthebox", "me", "device_id", {}).."/service")
end
function confirm_service(service)
        return POST('devices/'..uci:get("overthebox", "me", "device_id", {}).."/service/"..service.."/confirm", nil )
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
	local body, code, headers, status = http.request{
		method = method,
		url = url,
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




-- helpers

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



function error(str)
        p.syslog( p.LOG_ERROR, opts["i"] .. '.' .. str)
end
function log(str)
        p.syslog( p.LOG_NOTICE, opts["i"] .. '.' .. str)
end
function debug(str)
        p.syslog( p.LOG_DEBUG, opts["i"] .. '.' .. str)
end



-- Debug utils
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


