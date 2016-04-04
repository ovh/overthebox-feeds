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

local require 	= require
local json	= require "luci.json"
local sys 	= require "luci.sys"

local http	= require("socket.http")
local https	= require("ssl.https")
local ltn12	= require("ltn12")
local io 	= require("io")
local os 	= require("os")
local string	= require("string")

local print = print
local ipairs, pairs, next, type, tostring, tonumber, error = ipairs, pairs, next, type, tostring, tonumber, error
local table, setmetatable, getmetatable = table, setmetatable, getmetatable

local uci	= require("luci.model.uci")
debug = false
local VERSION = "<VERSION>"
module "overthebox"
_VERSION = VERSION
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
		local uci = uci.cursor()
		uci:set("overthebox", "me", "token", res.token)
		uci:set("overthebox", "me", "device_id", res.device_id)
		uci:save("overthebox")
		uci:commit("overthebox")
	end
	return (rcode == 200), res
end

function status()
	return GET('devices/'.. (uci.cursor():get("overthebox", "me", "device_id", {}) or "null").."/actions")
end

function exists(obj, ...)
	for i,v in ipairs(arg) do
		if obj[v] == nil then
			return false
		end
	end
	return true
end

function addInterfaceInZone(name, ifname)
	local uci = uci.cursor()
	uci:foreach("firewall", "zone",
		function (zone)
			if zone["name"] == name then
				local list = uci:get_list("firewall", zone[".name"], "network")
				if list then
					local zones = {}
					list = table.concat(list, " "):gmatch("%S+")
					for itf in list do
						if itf == ifname then
							return false;
						end
						table.insert(zones, itf)
					end
					table.insert(zones, ifname)
					uci:set_list("firewall", zone[".name"], "network", zones)
					uci:save('firewall')
					uci:commit('firewall')
					return true
				else
					uci:set_list("firewall", zone[".name"], "network", { ifname })
					uci:save('firewall')
					uci:commit('firewall')
					return true
				end
			end
		end
	)
	return false
end

function config()
	local uci = uci.cursor()
	local rcode, res = GET('devices/'..uci:get("overthebox", "me", "device_id", {}).."/config")
	local ret = {}

	if res.vtun_conf and exists( res.vtun_conf, 'server', 'port', 'cipher', 'psk', 'dev', 'ip_peer', 'ip_local', 'metric' ) then
		uci:set('vtund', 'tunnel', 'client')
		uci:set('vtund', 'tunnel', 'server', res.vtun_conf.server )
		uci:set('vtund', 'tunnel', 'port',   res.vtun_conf.port )
		uci:set('vtund', 'tunnel', 'cipher', res.vtun_conf.cipher )
		uci:set('vtund', 'tunnel', 'psk',    res.vtun_conf.psk )
		uci:set('vtund', 'tunnel', 'localip', res.vtun_conf.ip_local)
		uci:set('vtund', 'tunnel', 'remoteip', res.vtun_conf.ip_peer)

		uci:set('vtund', 'tunnel', 'table', res.vtun_conf.table)
		uci:set('vtund', 'tunnel', 'pref', res.vtun_conf.pref)
		uci:set('vtund', 'tunnel', 'metric', res.vtun_conf.metric)

		uci:set('network', res.vtun_conf.dev, 'interface')
		uci:set('network', res.vtun_conf.dev, 'ifname', res.vtun_conf.dev)
		uci:set('network', res.vtun_conf.dev, 'proto', 'none')
		uci:set('network', res.vtun_conf.dev, 'multipath', 'off')
		uci:set('network', res.vtun_conf.dev, 'delegate', '0')
		uci:set('network', res.vtun_conf.dev, 'metric', res.vtun_conf.metric)
		uci:set('network', res.vtun_conf.dev, 'auto', '0')
		uci:set('network', res.vtun_conf.dev, 'type', 'tunnel')

		addInterfaceInZone("wan", res.vtun_conf.dev)

		if exists( res.vtun_conf, 'additional_interfaces') and type(res.vtun_conf.additional_interfaces) == 'table' then
			for _, conf in pairs(res.vtun_conf.additional_interfaces) do
				if conf and exists( conf, 'dev', 'ip_peer', 'ip_local', 'port', 'mtu', 'table', 'pref', 'metric' ) then

					uci:set('vtund', conf.dev, 'interface')
					uci:set('vtund', conf.dev, 'remoteip', conf.ip_peer)
					uci:set('vtund', conf.dev, 'localip', conf.ip_local)
					uci:set('vtund', conf.dev, 'port', conf.port)
					uci:set('vtund', conf.dev, 'mtu', conf.mtu)

					uci:set('vtund', conf.dev, 'table', conf.table)
					uci:set('vtund', conf.dev, 'pref', conf.pref)
					uci:set('vtund', conf.dev, 'metric', conf.metric)

					uci:set('network', conf.dev, 'interface')
					uci:set('network', conf.dev, 'ifname', conf.dev)
					uci:set('network', conf.dev, 'proto', 'none')
					uci:set('network', conf.dev, 'multipath', 'off')
					uci:set('network', conf.dev, 'delegate', '0')
					uci:set('network', conf.dev, 'metric', conf.metric)
					uci:set('network', conf.dev, 'auto', '0')
					uci:set('network', conf.dev, 'type', 'tunnel')

					addInterfaceInZone("wan", conf.dev)

				end
			end
		end
		uci:save('network')
		uci:commit('network')
		
		uci:save('vtund')
		uci:commit('vtund')
		table.insert(ret, "vtund")

	end

	if res.glorytun_conf and exists( res.glorytun_conf, 'server', 'port', 'key', 'dev', 'ip_peer', 'ip_local', 'mtu' ) then
		uci:set('glorytun', 'otb', 'tunnel')

		uci:set('glorytun', 'otb', 'dev',     res.glorytun_conf.dev )

		uci:set('glorytun', 'otb', 'server',  res.glorytun_conf.server)
		uci:set('glorytun', 'otb', 'port',    res.glorytun_conf.port)
		uci:set('glorytun', 'otb', 'key',     res.glorytun_conf.key)

		uci:set('glorytun', 'otb', 'iplocal', res.glorytun_conf.ip_local)
		uci:set('glorytun', 'otb', 'ippeer',  res.glorytun_conf.ip_peer)
		uci:set('glorytun', 'otb', 'mtu',     res.glorytun_conf.mtu )

		uci:set('glorytun', 'otb', 'table',   res.glorytun_conf.table )
		uci:set('glorytun', 'otb', 'pref',    res.glorytun_conf.pref )
		uci:set('glorytun', 'otb', 'metric',  res.glorytun_conf.metric )

		uci:set('network', res.glorytun_conf.dev, 'interface')
		uci:set('network', res.glorytun_conf.dev, 'ifname', res.glorytun_conf.dev)
		uci:set('network', res.glorytun_conf.dev, 'proto', 'none')
		uci:set('network', res.glorytun_conf.dev, 'multipath', 'off')
		uci:set('network', res.glorytun_conf.dev, 'delegate', '0')
		uci:set('network', res.glorytun_conf.dev, 'metric', res.glorytun_conf.metric)
		uci:set('network', res.glorytun_conf.dev, 'auto', '0')
		uci:set('network', res.glorytun_conf.dev, 'type', 'tunnel')

		addInterfaceInZone("wan", res.glorytun_conf.dev)

		if exists( res.glorytun_conf, 'additional_interfaces') and type(res.glorytun_conf.additional_interfaces) == 'table' then
			for _, conf in pairs(res.glorytun_conf.additional_interfaces) do
				if conf and exists( conf, 'dev', 'ip_peer', 'ip_local', 'port', 'mtu', 'table', 'pref', 'metric' ) then

					uci:set('glorytun', conf.dev, 'tunnel')

					uci:set('glorytun', conf.dev, 'dev', conf.dev)

					uci:set('glorytun', conf.dev, 'server', conf.server or res.glorytun_conf.server)
					uci:set('glorytun', conf.dev, 'port', conf.port)
					uci:set('glorytun', conf.dev, 'key', conf.key or res.glorytun_conf.key)

					uci:set('glorytun', conf.dev, 'iplocal', conf.ip_local)
					uci:set('glorytun', conf.dev, 'ippeer', conf.ip_peer)
					uci:set('glorytun', conf.dev, 'mtu', conf.mtu)

					uci:set('glorytun', conf.dev, 'table', conf.table)
					uci:set('glorytun', conf.dev, 'pref', conf.pref)
					uci:set('glorytun', conf.dev, 'metric', conf.metric)

					uci:set('network', conf.dev, 'interface')
					uci:set('network', conf.dev, 'ifname', conf.dev)
					uci:set('network', conf.dev, 'proto', 'none')
					uci:set('network', conf.dev, 'multipath', 'off')
					uci:set('network', conf.dev, 'delegate', '0')
					uci:set('network', conf.dev, 'metric', conf.metric)
					uci:set('network', conf.dev, 'auto', '0')
					uci:set('network', conf.dev, 'type', 'tunnel')

					addInterfaceInZone("wan", conf.dev)

				end
			end
		end

		uci:save('glorytun')
		uci:commit('glorytun')

		table.insert(ret, 'glorytun')
	end

	if not res.tun_conf then
		res.tun_conf = {}
	end
	if not res.tun_conf.app then
		res.tun_conf.app = "none"
	end

	if res.tun_conf.app == 'glorytun' then
		uci:foreach("glorytun", "tunnel",
			function (e)
				uci:set('glorytun', e[".name"], 'enable', '1' )
			end
		)
		uci:set('mwan3', 'socks', 'dest_ip', res.glorytun_conf.server)
	else
		uci:foreach("glorytun", "tunnel",
			function (e)
				uci:set('glorytun', e[".name"], 'enable', '0' )
			end
		)
	end
	uci:save('glorytun')
	uci:commit('glorytun')

	if res.tun_conf.app == 'vtun' then
		uci:set('vtund', 'tunnel', 'enable', '1')
		uci:foreach("vtund", "interface",
			function (e)
				uci:set('vtund', e[".name"], 'enable', '1' )
			end
		)
		uci:set('mwan3', 'socks', 'dest_ip', res.vtun_conf.server)
	else
		uci:set('vtund', 'tunnel', 'enable', '0')
		uci:foreach("vtund", "interface",
			function (e)
				uci:set('vtund', e[".name"], 'enable', '0' )
			end
		)
	end
	uci:save('vtund')
	uci:commit('vtund')

	uci:delete('mwan3', 'socks', 'dest_port')
	uci:save('mwan3')
	uci:commit('mwan3')

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

	if res.graph_conf and exists( res.graph_conf, 'host', 'write_token') then
		uci:set('scollector','opentsdb', 'client')
		uci:set('scollector', 'opentsdb', 'host', res.graph_conf.host )
		uci:set('scollector', 'opentsdb', 'freq', (res.graph_conf.write_frequency or 300) )
		uci:set('scollector', 'opentsdb', 'wrtoken', res.graph_conf.write_token )

		uci:save('scollector')
		uci:commit('scollector')
		table.insert(ret, 'scollector')
	end

	if res.log_conf and exists( res.log_conf, 'host', 'port') then

		uci:foreach("system", "system",
			function (e)
				uci:set('system', e[".name"], 'log_ip', res.log_conf.host )
				uci:set('system', e[".name"], 'log_port', res.log_conf.port )
			end
		)

		uci:save('system')
		uci:commit('system')

		table.insert(ret, 'log')
	end

	return true, ret 
end

function send_properties( props )
	body = {}

	local uci = uci.cursor()
	if props.interfaces then
		body.interfaces = {}
		uci:foreach("network", "interface",
			function (e)
				if not e.ifname then
					return
				end
				entry = {
					ip=e.ipaddr,
					netmask=e.netmask,
					gateway=e.gateway,
					name=e.ifname,
					multipath_status=e.multipath
				}
				if e.dns then
					entry.dns_servers = string.gmatch( e.dns , "%S+")
				end
				if e.gateway then
					entry.public_ip = get_ip_public(e.ifname)
				end

				table.insert( body.interfaces, entry)
			end
		)
	end

	if props.packages then
		body.packages = {}
		for i, pkg in pairs(props.packages) do
			local ret = chomp(run("opkg status ".. pkg .. " |grep Version: "))
			ret = string.gsub(ret, "Version: ", "" ) -- remove Version: prefix
			table.insert( body.packages, {name=pkg, version=ret})
		end
	end

	if props.mounts then
		body.mounts = get_mounts()
	end

--	tprint(body)

	local rcode, res = POST('devices/'.. (uci:get("overthebox", "me", "device_id", {}) or "null")..'/properties',  body)
	tprint(res)
	print(rcode)
	return (rcode == 200), res
end

function get_mounts()
	local mounts = {}
	for line in io.lines("/proc/mounts") do
		t = split(line)
		table.insert(mounts, {device=t[1], mount_point=t[2], fs=t[3], options=t[4]})
	end
	return mounts
end

function checkReadOnly()
	for _, mount in pairs(get_mounts()) do
		if mount.mount_point and mount.mount_point == "/" then
			if mount.options and mount.options:match("^ro") then -- assume ro is always the first of the option
				return true
			end
		end
	end
	return false
end

function get_ip_public(interface)
	return run("curl -s --connect-timeout 1 --interface "..interface.." ifconfig.ovh" ):match("(%d+%.%d+%.%d+%.%d+)")
end

function check_release_channel(rc)
	local myrc = uci.cursor():get("overthebox", "me", "release_channel", {}) or ""
	return myrc == rc
end

function update_release_channel()
	local uci = uci.cursor()
	local rcode, res = GET('devices/'..uci:get("overthebox", "me", "device_id", {}).."/release_channel")
	if rcode == 200 then
		if res.feeds then
			set_feeds(res.feeds)
		end
		if res.name and res.image_url then
			uci:set("overthebox", "me", "release_channel", res.name)
			uci:set("overthebox", "me", "image_url", res.image_url)
			uci:save('overthebox')
			uci:commit('overthebox')
		end
		return true, "ok"
	end
	return false, "error"
end

-- write feeds in distfeeds.conf file
function set_feeds(feeds)
	local txt = ""
	for i, f in pairs(feeds) do
		txt = txt .. f.type .. " " .. f.name .. " " ..f.url .."\n"
	end

	if txt ~= "" then
		fd = io.open("/etc/opkg/distfeeds.conf", "w")
		if fd then
			fd:write("# generated file, do not edit\n")
			fd:write(txt)
			fd:close()
		end
	end
end


function createKey(remoteId)
	ret, key = create_ssh_key()
	if ret and key then
		local rcode, res = POST('devices/'..uci.cursor():get("overthebox", "me", "device_id", {}).."/remote_accesses/"..remoteId.."/keys",   {public_key=key})
		return (rcode == 200), "ok"
	end
	return false, "key not well created"
end

function create_ssh_key()
	local private_key = "/root/.ssh_otb_remote"
	local public_key = private_key..".pub"

	if not file_exists( private_key ) then
		local ret = run("dropbearkey -t rsa -s 4096 -f ".. private_key .. " |grep ^ssh- > ".. public_key)
	end
	if not file_exists( public_key ) then
		local ret = run("dropbearkey -t rsa -s 4096 -f ".. private_key .. " -y |grep ^ssh- > ".. public_key )
	end

	key=""
	-- read public key
	for line in io.lines(public_key) do
		if string_starts( line, "ssh-") then
			key = line
			break
		end
	end

	return true, key
end

function remoteAccessConnect(args)
	if not args or not exists( args, 'forwarded_port', 'ip', 'port', 'server_public_key', 'remote_public_key')    then
		return false, "no arguments or missing"
	end

	local name="remote"..args.port
	-- set arguments to config
	local uci = uci.cursor()
	uci:set("overthebox", name, "remote")
	uci:set("overthebox", name, "forwarded_port", args.forwarded_port )
	uci:set("overthebox", name, "ip", args.ip )
	uci:set("overthebox", name, "port", args.port )
	uci:set("overthebox", name, "server_public_key", args.server_public_key)
	uci:set("overthebox", name, "remote_public_key", args.remote_public_key)

	uci:save("overthebox")
	uci:commit("overthebox")

	local ret = run("/etc/init.d/otb-remote restart")
	return true, "ok"
end

function remoteAccessDisconnect(args)
	if not args then
		return false, "no arguments"
	end

	local name="remote"..args.port

	local uci = uci.cursor()
	uci:delete("overthebox", name)
	uci:commit("overthebox")
	uci:save("overthebox")

	local ret = run("/etc/init.d/otb-remote stop")
	return true, "ok"
end

function string_starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

function file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

-- exec command local
function restart(service)
	local ret = run("/etc/init.d/"..service.." restart")
	return true, ret
end
function restartmwan3()
	local ret = os.execute("/usr/sbin/mwan3 restart")
	return true, ret
end


function opkg_update()
	local ret = run("opkg update 2>&1")
	return true, ret
end

function opkg_upgradable()
	local ret = run("opkg list-upgradable")
	return true, ret
end
function opkg_install(package)
	local ret = run("opkg install "..package.. " --force-overwrite 2>&1" ) -- to fix
	return true, ret
end
function opkg_remove(package)
	local ret = run("opkg remove "..package )
	return true, ret
end

function upgrade()
	local packages = {'overthebox', 'mptcp', 'netifd', 'luci-base', 'luci-mod-admin-full', 'luci-app-overthebox', 'mwan3otb', 'luci-app-mwan3otb', 'shadowsocks-libev', 'bosun', 'vtund', 'luci-theme-ovh', 'dnsmasq-full', 'sqm-scripts', 'luci-app-sqm', 'e2fsprogs', 'e2freefrag', 'dumpe2fs', 'resize2fs', 'tune2fs', 'libsodium', 'glorytun', 'rdisc6'}
	local unwantedPackages = {'luci-app-qos', 'qos-scripts'}
	local retcode = true
	local ret = "install:\n"
	for i = 1, #packages do
		-- install package
		local p = packages[i]
		local c, r = opkg_install(p)
		if c == false then
			retcode = false
		end
		ret = ret ..  p .. ": \n" .. r .."\n"
	end

	ret = ret .. "\nuninstall:\n"
	for i = 1, #unwantedPackages do
		-- install package
		local p = unwantedPackages[i]
		local c, r = opkg_remove(p)
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
	local uci = uci.cursor()
	uci:set("overthebox", "me", "last_action_id", id)
	uci:save("overthebox")
	uci:commit("overthebox")
end

function get_last_action()
	return uci.cursor():get("overthebox", "me", "last_action_id")
end

function flush_action(id)
	local uci = uci.cursor()
	uci:delete("overthebox", "me", "last_action_id", id)
	uci:save("overthebox")
	uci:commit("overthebox")
end


function confirm_action(action, status, msg )
	if action == nil then
		return false, {error = "Can't confirm a nil action"}
	end
	if msg == nil then
		msg = ""
	end
	if status == nil then
		status = "error"
	end

	local rcode, res = POST('devices/'..uci.cursor():get("overthebox", "me", "device_id", {}).."/actions/"..action, {status=status, details = msg})

	return (rcode == 200), res
end

-- notification events
function notify_boot()
	send_properties( {interfaces="all"} )
	return notify("BOOT")
end
function notify_shutdown()
	return notify("SHUTDOWN")
end
function notify_ifdown(iface)
	mprobe = uci.cursor():get("mwan3", iface, "track_method") or ""
	return notify("IFDOWN", {interface=iface, probe=mprobe})
end
function notify_ifup(iface)
	mprobe = uci.cursor():get("mwan3", iface, "track_method") or ""
	return notify("IFUP", {interface=iface, probe=mprobe})
end
function notify(event, details)
	return POST('devices/'..(uci.cursor():get("overthebox", "me", "device_id", {}) or "none" ).."/events", {event_name = event, timestamp = os.time(), details = details})
end


-- service ovh
function ask_service_confirmation(service)
	local uci = uci.cursor()
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
	local rcode, ret = GET('devices/'..uci.cursor():get("overthebox", "me", "device_id", {}).."/service")
	return (rcode == 200), ret
end
function confirm_service(service)
	local uci = uci.cursor()
	if service ~= uci:get("overthebox", "me", "service") then
		return false, "service does not match"
	end

	local rcode, ret = POST('devices/'..uci:get("overthebox", "me", "device_id", {}).."/service/"..service.."/confirm", nil )
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
	http.TIMEOUT=5
	local body, code, headers, status = https.request{
		method = method,
		url = url,
		protocol = "tlsv1",
		headers = 
		{
			["Content-Type"] = "application/json",
			["Content-length"] = reqbody:len(),
			["X-Auth-OVH"] = uci.cursor():get("overthebox", "me", "token"),
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

-- Remove any final \n from a string.
--   s: string to process
-- returns
--   s: processed string
function chomp(s)
	return string.gsub(s, "\n$", "")
end

function split(t)
	local r = {}
	for v in string.gmatch(t, "%S+") do
		table.insert(r, v)
	end
	return r
end


-- Mwan conf generator
function update_confmwan()
	local uci = uci.cursor()
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

	uci:foreach("mwan3", "interface",
	  function (section)
	    if uci:get("network",section[".name"]) == nil then
	        uci:delete("mwan3", section[".name"])
	    end
	  end
	)

	uci:foreach("mwan3", "member",
	  function (section)
	    local interface
	    interface=uci:get("mwan3",section[".name"],"interface")
	    if interface ~= nil then
	      if uci:get("mwan3",interface) == nil then
	        uci:delete("mwan3", section[".name"])
	      end
	    else
	      uci:delete("mwan3", section[".name"])
	    end
	  end
	)

	uci:foreach("mwan3", "policy",
	  function (section)
	    local list
	    local nlist={}
	    local i
	    list = uci:get_list("mwan3",section[".name"], "use_member")
	    for i=1,#list do
	      if uci:get("mwan3",list[i]) ~= nil then
	        table.insert(nlist,list[i])
	      end
	    end
	    if #nlist == 0 then
	      uci:delete("mwan3", section[".name"])

	    else
	      if #list ~= #nlist then
	        uci:set_list("mwan3", section[".name"], "use_member", nlist)
	      end
	    end
	  end
	)

	uci:foreach("mwan3", "rule",
		function (section)
			if string.match(section[".name"], "^dns_") then
				uci:delete("mwan3", section[".name"])
			end
		end
	)
	uci:foreach("mwan3", "policy",
		function (section)
			if string.match(section[".name"], "^dns_") then
				uci:delete("mwan3", section[".name"])
			end
		end
	)
	-- Setup trackers IPs
	local tracking_servers = {}
	table.insert( tracking_servers, "51.254.49.132" )
	table.insert( tracking_servers, "51.254.49.133" )
	-- 
	local interfaces={}
	local size_interfaces = 0 -- table.getn( does not work....

	-- Table indexed with dns ips to list reacheable interface for this DNS ip
	local dns_policies = {}

	-- Create a tracker for each mptcp interface
	uci:foreach("network", "interface",
		function (section)
			if section["multipath"] == "on" or section["multipath"] == "master" or section["multipath"] == "backup" or section["multipath"] == "handover" then
				if section["gateway"] then
					size_interfaces = size_interfaces + 1
					interfaces[ section[".name"] ] = section
					uci:set("mwan3", section[".name"], "interface")
					uci:set("mwan3", section[".name"], "enabled", "1")
					if next(tracking_servers) then
						uci:set_list("mwan3", section[".name"], "track_ip", tracking_servers)
					end
					if uci:get("mwan3", section[".name"], "track_method") == nil then
					  uci:set("mwan3", section[".name"], "track_method","dns")
					  uci:set("mwan3", section[".name"], "reliability", "1")
					  uci:set("mwan3", section[".name"], "count", "1")
					  uci:set("mwan3", section[".name"], "timeout", "2")
					  uci:set("mwan3", section[".name"], "interval", "5")
					  uci:set("mwan3", section[".name"], "down", "3")
					  uci:set("mwan3", section[".name"], "up", "3")
					end
					if section["dns"] then
						local seen = {}
						for dns in string.gmatch(section["dns"], "%S+") do
							if seen[dns] == nil then
								if dns_policies[dns] == nil then
									dns_policies[dns] = {}
								end
								seen[dns] = section[".name"]
								table.insert(dns_policies[dns], section[".name"])
							end
						end
					end
				end
			elseif section["type"] == "tunnel" then
				size_interfaces = size_interfaces + 1
				interfaces[section[".name"]] = section
				-- Create a tracker used to monitor tunnel interface
				uci:set("mwan3", section[".name"], "interface")
				uci:set("mwan3", section[".name"], "enabled", "1")
				uci:delete("mwan3", section[".name"], "track_ip") -- No tracking ip for tunnel interface
				uci:set("mwan3", section[".name"], "reliability", "1")
				uci:set("mwan3", section[".name"], "count", "1")
				uci:set("mwan3", section[".name"], "timeout", "2")
				uci:set("mwan3", section[".name"], "interval", "5")
				uci:set("mwan3", section[".name"], "down", "3")
				uci:set("mwan3", section[".name"], "up", "3")
			elseif section[".name"] == "tun0" then
				size_interfaces = size_interfaces + 1
				interfaces[section[".name"]] = section
				-- Create a tun0 tracker used for non tcp traffic
				uci:set("mwan3", "tun0", "interface")
				uci:set("mwan3", "tun0", "enabled", "1")
				uci:delete("mwan3", "tun0", "track_ip") -- No tracking ip so tun0 is always up
				uci:set("mwan3", "tun0", "reliability", "1")
				uci:set("mwan3", "tun0", "count", "1")
				uci:set("mwan3", "tun0", "timeout", "2")
				uci:set("mwan3", "tun0", "interval", "5")
				uci:set("mwan3", "tun0", "down", "3")
				uci:set("mwan3", "tun0", "up", "3")
			end
		end
	)
	-- generate all members
	local members = {}

	local members_wan = {}
	local members_tun = {}
	local members_qos = {}

	local list_interf = {}
	local list_wan 	  = {}
	local list_tun	  = {}
	local list_qos    = {}

	-- sorted iterator to sort interface by metric
	function __genOrderedIndex( t )
		local orderedIndex = {}
		for key in pairs(t) do
			table.insert( orderedIndex, key )
		end
		table.sort( orderedIndex, function (a, b) 
			return tonumber(interfaces[a].metric or 0) < tonumber(interfaces[b].metric or 0)
		end )
		return orderedIndex
	end

	function orderedNext(t, state)
		key = nil
		if state == nil then
			t.__orderedIndex = __genOrderedIndex( t )
			key = t.__orderedIndex[1]
		else
			for i = 1,table.getn(t.__orderedIndex) do
				if t.__orderedIndex[i] == state then
					key = t.__orderedIndex[i+1]
				end
			end
		end
		if key then
			return key, t[key]
		end
		t.__orderedIndex = nil
		return
	end

	function sortByMetric(t)
		return orderedNext, t, nil
	end
	-- create interface members
	for name, interf in sortByMetric(interfaces) do
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
			-- parc type of members
			if interf[".name"] == "tun0" then
				if not members_tun[metric] then
					members_tun[metric] = {}
				end
				if not list_tun[metric] then
					list_tun[metric] = {}
				end
				table.insert(members_tun[metric], name)
				table.insert(list_tun[metric], interf[".name"])

			elseif interf["type"] == "tunnel" then
				if not members_qos[metric] then
					members_qos[metric] = {}
				end
				if not list_qos[metric] then
					list_qos[metric] = {}
				end
				table.insert(members_qos[metric], name)
				table.insert(list_qos[metric], interf[".name"])
			elseif interf["multipath"] == "on" or interf["multipath"] == "master" or interf["multipath"] == "backup" or interf["multipath"] == "handover" then
				if not members_wan[metric] then
					members_wan[metric] = {}
				end
				if not list_wan[metric] then
					list_wan[metric] = {}
				end
				table.insert(members_wan[metric], name)
				table.insert(list_wan[metric], interf[".name"])
			end
			-- populating ref tables
			table.insert(members[metric], name)
			table.insert(list_interf[metric], interf[".name"])
			--- Creating mwan3 member
			uci:set("mwan3", name, "member")
			uci:set("mwan3", name, "interface", interf[".name"])
			uci:set("mwan3", name, "metric", metric)
			uci:set("mwan3", name, "weight", 1)
		end
	end
	-- generate policies
	if #members_wan and members_wan[1] then
		log("Creating mwan balanced policy")
		uci:set("mwan3", "balanced", "policy")
		uci:set_list("mwan3", "balanced", "use_member", members_wan[1])
	end

	if #members_tun and members_tun[1] then
		uci:set("mwan3", "balanced_tuns", "policy")
		uci:set_list("mwan3", "balanced_tuns", "use_member", members_tun[1])
	end

	if #members_qos and members_qos[1] then
		uci:set("mwan3", "balanced_qos", "policy")
		uci:set_list("mwan3", "balanced_qos", "use_member", members_qos[1])
	end

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
		if #members_tun then
			for i=1,#members_tun[1] do
				table.insert(my_members, members_tun[i][i])
			end
		end
		if #members_wan then
			for i=1,#members_wan[1] do
				if members_wan[i + #members_tun[1]] then
					table.insert(my_members, members_wan[#my_members + 1][i])
				end
			end
		end
		uci:set_list("mwan3", "failover", "use_member", my_members)
		uci:set("mwan3", "all", "use_policy", "failover")

		-- Generate qos failover policy
		if #members_qos and members_qos[1] then
			for i=1,#members_qos[1] do
				local name = list_qos[1][i].."_failover"
				uci:set("mwan3", name, "policy")
				local my_members = {}
				table.insert(my_members, members_qos[1][i])
				for j=i,#list_wan[1] do
					table.insert(my_members, members_wan[j + 1][j])
				end
				uci:set_list("mwan3", name, "use_member", my_members)
				if list_qos[1][i] == "xtun0" then
					uci:set("mwan3", "voip", "use_policy", name)
				end
			end
		end
	end

	-- Generate DNS policy
	local count = 0
	for dns, interfaces in pairs(dns_policies) do
		count = count + 1;
		local members = {};
		for i=1,#interfaces do
			table.insert(members, interfaces[i].."_m1_w1")
		end
		table.insert(members, "tun0_m2_w1")

		uci:set("mwan3", "dns_p_" .. count, "policy")
		uci:set_list("mwan3", "dns_p_" .. count, "use_member", members)
		uci:set("mwan3", "dns_p_" .. count, "last_resort", "default")

		uci:set("mwan3", "dns_" .. count, "rule")
		uci:set("mwan3", "dns_" .. count, "proto", "udp")
		uci:set("mwan3", "dns_" .. count, "sticky", "0")
		uci:set("mwan3", "dns_" .. count, "use_policy", "dns_p_" .. count)
		uci:set("mwan3", "dns_" .. count, "dest_ip", dns)
		uci:set("mwan3", "dns_" .. count, "dest_port", 53)
		uci:reorder("mwan3", "dns_" .. count, count - 1)

	end

	uci:set("mwan3", "netconfchecksum", newmd5)
	uci:save("mwan3")
	uci:commit("mwan3")
	-- Saving net conf md5 and restarting services
	if os.execute("mwan3 status 1>/dev/null 2>/dev/null") == 0 then
		os.execute("/etc/init.d/network reload")
		os.execute("/etc/init.d/firewall reload")
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

function ipv6_discover(interface)
	local interface = interface or 'eth0'
	local result = {}

	local ra6_list = (sys.exec("rdisc6 -nm " .. interface))
	-- dissect results
	local lines = {}
	local index = {}
	ra6_list:gsub('[^\r\n]+', function(c)
		table.insert(lines, c)
		if c:match("Hop limit") then
			table.insert(index, #lines)
		end
	end)
	local ra6_result = {}
	for k,v in ipairs(index) do
		local istart = v
		local iend = index[k+1] or #lines

		local entry = {}
		for i=istart,iend - 1 do
			local level = lines[i]:find('%w')
			local line = lines[i]:sub(level)

			local param, value
			if line:match('^from') then
				param, value = line:match('(from)%s+(.*)$')
			else
				param, value = line:match('([^:]+):(.*)$')
				-- Capitalize param name and remove spaces
				param = param:gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end):gsub("[%s-]",'')
				param = param:gsub("%.$", '')
				-- Remove text between brackets, seconds and spaces
				value = value:lower()
				value = value:gsub("%(.*%)", '')
				value = value:gsub("%s-seconds%s-", '')
				value = value:gsub("^%s+", '')
				value = value:gsub("%s+$", '')
			end

			if entry[param] == nil then
				entry[param] = value
			elseif type(entry[param]) == "table" then
				table.insert(entry[param], value)
			else
				old = entry[param]
				entry[param] = {}
				table.insert(entry[param], old)
				table.insert(entry[param], value)
			end
		end
		table.insert(ra6_result, entry)
	end
--	tprint(ra6_result)
	return ra6_result
end

function create_dhcp_server()
	local result = {}
	local uci = uci.cursor()
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
							uci:set("dhcp", section[".name"], "authoritative", "0")
							uci:set("dhcp", section[".name"], "ignore", "0")
							uci:set("dhcp", section[".name"], "force", "1")
							uci:set("dhcp", section[".name"], "start", "50")
							uci:set("dhcp", section[".name"], "limit", "200")
							uci:set("dhcp", section[".name"], "leasetime", "12h")
--							uci:set("dhcp", section[".name"], "dhcp_option", "option:router," .. uci:get("interface", section[".name"], 'ipaddr') .. ' ' .. "option:dns-server," .. uci:get("interface", section[".name"], 'ipaddr'))
--							sys.exec("echo 'host-record=overthebox.ovh,".. section["ipaddr"]  .."'  >> /etc/dnsmasq.conf")
							dhcpd_configured = dhcpd_configured + 1
							return;
						end
					end
				end
			)
		else
			uci:set("dhcp", minMetricInterface, "dhcp")
			uci:set("dhcp", minMetricInterface, "interface", minMetricInterface)
			uci:set("dhcp", minMetricInterface, "authoritative", "0")
			uci:set("dhcp", minMetricInterface, "ignore", "0")
			uci:set("dhcp", minMetricInterface, "force", "1")
			uci:set("dhcp", minMetricInterface, "start", "50")
			uci:set("dhcp", minMetricInterface, "limit", "200")
			uci:set("dhcp", minMetricInterface, "leasetime", "12h")
--			uci:set("dhcp", minMetricInterface, "dhcp_option", "option:router," .. uci:get("network", minMetricInterface, 'ipaddr') .. ' ' .. "option:dns-server," .. uci:get("network", minMetricInterface, 'ipaddr'))
--			sys.exec("echo 'host-record=overthebox.ovh,".. uci:get("network", minMetricInterface, 'ipaddr') .."'  >> /etc/dnsmasq.conf")
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
				addr	= a:host():string(),
				netmask	= a:mask():string(),
				prefix	= a:prefix()
			}
		end
		-- populate ipv6 address
		for _, a in ipairs(device:ip6addrs()) do
			if not a:is6linklocal() then
				result.ip6addrs[#result.ip6addrs+1] = {
					addr	= a:host():string(),
					netmask	= a:mask():string(),
					prefix	= a:prefix()
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


