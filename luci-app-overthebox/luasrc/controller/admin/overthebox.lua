-- Copyright 2015 OVH <OverTheBox@ovh.net>
-- Simon Lelievre (simon.lelievre@corp.ovh.com)
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

local tools = require "luci.tools.status"
local sys = require "luci.sys"
local json      = require("luci.json")
module("luci.controller.admin.overthebox", package.seeall)

function index()
	-- main menu entry
	entry({"admin", "overthebox"}, firstchild(), _("OverTheBox"), 19).index = true
	-- submenu entries
	entry({"admin", "overthebox", "overview"}, template("overthebox/index"), _("Overview"), 1).leaf = true
	entry({"admin", "overthebox", "dscp"}, cbi("dscp/dscp"), _("DSCP Settings"), 2).leaf = true
	entry({"admin", "overthebox", "register_device"}, template("overthebox/register_device"), _("Register device"), 3).leaf = true
	entry({"admin", "overthebox", "lan_traffic"}, template("overthebox/lan_traffic"), _("LAN Traffic"), 4).leaf = true
	entry({"admin", "overthebox", "multipath"}, template("overthebox/multipath"), _("Realtime graphs"), 5).leaf = true
	entry({"admin", "overthebox", "tunnels"}, template("overthebox/tunnels"), _("TUN graphs"), 6).leaf = true
	entry({"admin", "overthebox", "qos"}, template("overthebox/qos"), _("QoS graphs"), 7).leaf = true
	-- functions
	entry({"admin", "overthebox", "qos_stats"}, call("action_qos_data")).leaf = true
	entry({"admin", "overthebox", "lan_traffic_data"}, call("action_lan_traffic_data")).leaf = true
	entry({"admin", "overthebox", "bandwidth_status"}, call("action_bandwidth_data")).leaf = true
	entry({"admin", "overthebox", "interfaces_status"}, call("interfaces_status")).leaf = true
	entry({"admin", "overthebox", "lease_overview"}, call("lease_overview")).leaf = true
	entry({"admin", "overthebox", "ipv6_discover"}, call("ipv6_discover")).leaf = true
	entry({"admin", "overthebox", "dhcp_status"}, call("dhcp_status")).leaf = true
	entry({"admin", "overthebox", "dhcp_recheck"}, call("action_dhcp_recheck")).leaf = true
	entry({"admin", "overthebox", "dhcp_skiptimer"}, call("action_dhcp_skip_timer")).leaf = true
	entry({"admin", "overthebox", "dhcp_start_server"}, call("action_dhcp_start_server")).leaf = true
	entry({"admin", "overthebox", "activate_service"}, call("action_activate")).leaf = true
	entry({"admin", "overthebox", "need_activate_service"},  call("need_activate")).leaf = true
	entry({"admin", "overthebox", "activate"}, template("overthebox/index")).leaf = true
	entry({"admin", "overthebox", "passwd"}, post("action_passwd")).leaf = true
	entry({"admin", "overthebox", "update_conf"}, call("action_update_conf")).leaf = true
end
	
function action_passwd()
	local result = {}
	result["status"] = false
	local p1 = luci.http.formvalue("p1")
	local p2 = luci.http.formvalue("p2")
	if p1 and p2 then
		if p1 == p2 then
			result["rcode"] = luci.sys.user.setpasswd("root", p1)
			result["status"] = (result["rcode"] ~= nil and result["rcode"] == 0)
			if result["status"] then
				result["error"] = false
			else
				result["error"] = "Internal error"
			end
		else
			result["status"] = false
			result["error"] = "passwords are not the same"
		end
	else
		result["error"] = "missing arguments"
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

-- Multipath overview functions
function interfaces_status()

	local mwan3 	= require("luci.controller.mwan3")
	local ut 	= require "luci.util"
	local ntm 	= require "luci.model.network".init()
	local uci 	= require "luci.model.uci".cursor()

	local logged	= isLogged()
	local mArray = {}

	-- Overthebox info
	mArray.overthebox = {}
	mArray.overthebox["version"] = require('overthebox')._VERSION
	-- Check that requester is in same network
	mArray.overthebox["service_addr"]	= uci:get("shadowsocks", "proxy", "server") or "0.0.0.0"
	mArray.overthebox["local_addr"]		= uci:get("network", "lan", "ipaddr")
	mArray.overthebox["wan_addr"]		= "0.0.0.0"
	local wanaddr = ut.trim(sys.exec("cat /tmp/wanip"))
	if string.match(wanaddr, "^%d+\.%d+\.%d+\.%d+$") then
		if logged then
			mArray.overthebox["wan_addr"] = wanaddr
		else
			mArray.overthebox["wan_addr"] = wanaddr:gsub("^(%d+)%.%d+%.%d+%.(%d+)", "%1.***.***.%2")
		end
	end
	mArray.overthebox["remote_addr"]	= luci.http.getenv("REMOTE_ADDR") or ""
	mArray.overthebox["remote_from_lease"]	= false
	 local leases=tools.dhcp_leases()
	for _, value in pairs(leases) do
		if value["ipaddr"] == mArray.overthebox["remote_addr"] then
			mArray.overthebox["remote_from_lease"] = true
			mArray.overthebox["remote_hostname"] = value["hostname"]
		end
	end
	-- Check overthebox service are running
	mArray.overthebox["tun_service"] = false
	if string.find(sys.exec("/usr/bin/pgrep '^(/usr/sbin/)?glorytun(-udp)?$'"), "%d+") then
		mArray.overthebox["tun_service"] = true
	end
	mArray.overthebox["socks_service"] = false
	if string.find(sys.exec("/usr/bin/pgrep ss-redir"), "%d+") then
		mArray.overthebox["socks_service"] = true
	end
	-- Check if OTB is downloading recovery image or test download
	mArray.overthebox["downloading"] = false
	if string.find(sys.exec("/usr/bin/pgrep wget"), "%d+") then
		mArray.overthebox["downloading"] = true
	end
	-- Check if OTB is installing updates
	mArray.overthebox["install_updates"] = false
	if string.find(sys.exec("/usr/bin/pgrep opkg"), "%d+") then
		mArray.overthebox["install_updates"] = true
	end
	-- Add DHCP infos by parsing dnsmask config file
	mArray.overthebox.dhcpd = {}
	dnsmasq = ut.trim(sys.exec("cat /var/etc/dnsmasq.conf*"))
	for itf, range_start, range_end, mask, leasetime in dnsmasq:gmatch("range=[%w,]*set:(%w+),(%d+\.%d+\.%d+\.%d+),(%d+\.%d+\.%d+\.%d+),(%d+\.%d+\.%d+\.%d+),(%w+)") do
		mArray.overthebox.dhcpd[itf] = {}
		mArray.overthebox.dhcpd[itf].interface = itf
		mArray.overthebox.dhcpd[itf].range_start = range_start
		mArray.overthebox.dhcpd[itf].range_end = range_end
		mArray.overthebox.dhcpd[itf].netmask = mask
		mArray.overthebox.dhcpd[itf].leasetime = leasetime
		mArray.overthebox.dhcpd[itf].router = mArray.overthebox["local_addr"]
		mArray.overthebox.dhcpd[itf].dns = mArray.overthebox["local_addr"]
	end
	for itf, option, value in dnsmasq:gmatch("option=(%w+),([%w:-]+),(%d+\.%d+\.%d+\.%d+)") do
		if mArray.overthebox.dhcpd[itf] then
			if option == "option:router" or option == "6" then
				mArray.overthebox.dhcpd[itf].router = value
			end
			if option == "option:dns-server" or option == "" then
				mArray.overthebox.dhcpd[itf].dns = value
			end
		end
	end
	-- Parse mptcp kernel info
	local mptcp = {}
	local fullmesh = ut.trim(sys.exec("cat /proc/net/mptcp_fullmesh"))
	for ind, addressId, backup, ipaddr in fullmesh:gmatch("(%d+), (%d+), (%d+), (%d+\.%d+\.%d+\.%d+)") do
		mptcp[ipaddr] = {}
		mptcp[ipaddr].index = ind
		mptcp[ipaddr].id    = addressId
		mptcp[ipaddr].backup= backup
		mptcp[ipaddr].ipaddr= ipaddr
	end
	-- retrive core temperature
	mArray.overthebox["core_temp"] = sys.exec("cat /sys/devices/platform/coretemp.0/hwmon/hwmon0/temp2_input 2>/dev/null"):match("%d+")
	mArray.overthebox["loadavg"] = sys.exec("cat /proc/loadavg 2>/dev/null"):match("[%d%.]+ [%d%.]+ [%d%.]+")
	mArray.overthebox["uptime"] = sys.exec("cat /proc/uptime 2>/dev/null"):match("[%d%.]+")
	-- overview status
	local statusString = mwan3.getInterfaceName()
	if statusString ~= "" then
		mArray.wans = {}
		wansid = {}
		mArray.tunnels = {}

		for wanName, interfaceState in string.gfind(statusString, "([^%[]+)%[([^%]]+)%]") do
		local wanInterfaceName = ut.trim(sys.exec("uci -q -p /var/state get network." .. wanName .. ".ifname"))
		if wanInterfaceName == "" then
			wanInterfaceName = "X"
		end
		local wanDeviceLink = ntm:get_interface(wanInterfaceName)
			wanDeviceLink = wanDeviceLink and wanDeviceLink:get_network()
			wanDeviceLink = wanDeviceLink and wanDeviceLink:adminlink() or "#"
			local wanLabel = uci:get("network", wanName, "label") or wanInterfaceName
			wansid[wanName] = #mArray.wans + 1
			-- Add multipath info
			local ipaddr	= uci:get("network", wanName, "ipaddr")
			local gateway	= uci:get("network", wanName, "gateway")
			local multipath = "default";
			if ipaddr and mptcp[ipaddr] then
				multipath = uci:get("network", wanName, "multipath") or "on"
			else
				multipath = "off"
			end
			-- Return info
			if wanName:match("tun[%d+]") or wanName:match("voip[%d+]") then
				mArray.tunnels[wanName] = { label = wanLabel, name = wanName, link = wanDeviceLink, ifname = wanInterfaceName, ipaddr = ipaddr, multipath = multipath, status = interfaceState }
			else
				-- Add ping info
				data = json.decode(ut.trim(sys.exec("cat /tmp/tracker/if/" .. wanName .. " 2>/dev/null")))
				local minping = "NaN"
				local avgping = "NaN"
				local curping = "NaN"
				local wanip   = "0.0.0.0"
				local whois   = "Unknown provider"
				local qos     = false
				local download
				local upload
				if data and data[wanName] then
					minping = data[wanName].minping
					avgping = data[wanName].avgping
					curping = data[wanName].curping
					whois	= data[wanName].whois
					wanip	= "0.0.0.0"
					if data[wanName].wanaddr then
						if logged then
							wanip   = data[wanName].wanaddr
						else
							wanip   = data[wanName].wanaddr:gsub("^(%d+)%.%d+%.%d+%.(%d+)", "%1.***.***.%2")
						end
					end
					-- append qos current state infos
					if data[wanName].qostimestamp and data[wanName].reloadtimestamp and data[wanName].qostimestamp > data[wanName].reloadtimestamp then
						if data[wanName].qosmode then
							qos = data[wanName].qosmode
						end
						if data[wanName].upload then
							upload = data[wanName].upload
						end
						if data[wanName].download then
							download = data[wanName].download
						end
					end
				end
				mArray.wans[wansid[wanName]] = { label = wanLabel, name = wanName, link = wanDeviceLink, ifname = wanInterfaceName, ipaddr = ipaddr, gateway = gateway, multipath = multipath, status = interfaceState, minping = minping, avgping = avgping, curping = curping, wanip = wanip, whois = whois, download = download, upload = upload, qos = qos }
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(mArray)
end

function isLogged()
	local sid = luci.http.getcookie('sysauth');
	if sid and (require('luci.util').ubus("session", "get", { ubus_rpc_session = sid }) or { }).values then
		return true
	else
		return false
	end
end

function lease_overview()
	local stat = require "luci.tools.status"
	local rv = {
		leases     = stat.dhcp_leases(),
		leases6    = stat.dhcp6_leases(),
		wifinets   = stat.wifi_networks()
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function write_qos_cache(data)
	local json_data = json.encode(data)
        local file = io.open( "/tmp/tc_stats", "w" )
        file:write(json_data)
        file:close()
end

function read_qos_cache()
	local data = {}
        local file = io.open( "/tmp/tc_stats", "r" )
	if file then
		local json_data = file:read("*all")
	        file:close()
		data = json.decode(json_data) or {}
	end
	return data
end

function action_qos_data()
	local data = read_qos_cache()
	local timestamp = os.time()
	local stats = require('overthebox').tc_stats()
	if stats and next(stats) ~= nil then
		data[timestamp] = stats
	end
	-- keep only last minute
	local striped_data = {}
	for k,v in pairs(data) do
		if tonumber(k) > tonumber(timestamp) - 60 then
			striped_data[k] = data[k]
		end
	end
	write_qos_cache(striped_data)
	-- format output
	luci.http.prepare_content("application/json")
	luci.http.write_json(striped_data)
end

function action_lan_traffic_data()
    local result = luci.sys.exec("bandwidth fetch json")
    luci.http.prepare_content("application/json")
    luci.http.write(result)
end

function action_bandwidth_data(dev)
	if dev ~= "all" then
		return require('luci.controller.admin.status').action_bandwidth(dev)
	else
		return multipath_bandwidth()
	end
end

function multipath_bandwidth()
	local result = { };
	local uci = luci.model.uci.cursor()

	result["wans"] = {};
	result["tuns"] = {};

	for _, dev in luci.util.vspairs(luci.sys.net.devices()) do
		if dev ~= "lo" then
			local multipath = uci:get("network", dev, "multipath")
			if multipath == "on" or multipath == "master" or multipath == "backup" or multipath == "handover" then
				result["wans"][dev] = "[" .. string.gsub((luci.sys.exec("luci-bwc -i %q 2>/dev/null" % dev)), '[\r\n]', '') .. "]"
			elseif uci:get("network", dev, "type") == "tunnel" then
				result["tuns"][dev] = "[" .. string.gsub((luci.sys.exec("luci-bwc -i %q 2>/dev/null" % dev)), '[\r\n]', '') .. "]"
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

-- DHCP overview functions
function ipv6_discover()
	local result = { };

	result = require('overthebox').ipv6_discover()

	if type(result) == "table" and #result > 1 then
		if not isLogged() then
			for k,v in ipairs(result) do
				if v.Prefix then
					result[k].Prefix = v.Prefix:gsub(":[%a%d]+:[%a%d]+([:]+/%d+)", ":****:****%1")
				end
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function dhcp_status()
        local uci = luci.model.uci.cursor()
        local result = {}
	-- Get alien dhcp list
        result.detected_dhcp_servers = {}
        uci:foreach("dhcpdiscovery", "lease",
                function (section)
                        result.detected_dhcp_servers[section[".name"]] = section
                end
        )
	-- List our DHCP service
	result.running_dhcp_service = require('overthebox').list_running_dhcp()
        uci:foreach("dhcp", "dhcp",
                function (section)
                        if result.running_dhcp_service[section[".name"]] then
                                result.running_dhcp_service[section[".name"]] = section
                                result.running_dhcp_service[section[".name"]].ipaddr = uci:get("network", section[".name"], "ipaddr")
                        end
                end
        )
	-- Return results
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
end

function action_activate(service)
	local result = require('overthebox').confirm_service(service)
	action_dhcp_start_server()
	action_dhcp_recheck()
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function need_activate()
	local result = { };
	local uci = luci.model.uci.cursor()
	luci.http.prepare_content("application/json")
	if uci:get("overthebox", "me", "askserviceconfirmation") == "1" then
		result["active"] = false
	else
		result["active"] = true
	end
	luci.http.write_json(result)
end

function action_dhcp_recheck()
	sys.exec("uci set dhcpdiscovery.if0.lastcheck=`date +%s`")
	sys.exec("uci delete dhcpdiscovery.if0.siaddr")
	sys.exec("uci delete dhcpdiscovery.if0.serverid")
	-- workaround for time jump at first startup
	local uci = luci.model.uci.cursor()
	local timestamp = uci:get("dhcpdiscovery", "if0", "timestamp")
	local lastcheck = uci:get("dhcpdiscovery", "if0", "lastcheck")
	if timestamp and lastcheck and (tonumber(timestamp) > tonumber(lastcheck)) then
		sys.exec("uci set dhcpdiscovery.if0.timestamp=" .. lastcheck)
	end

	sys.exec("uci commit")
	sys.exec("pkill -USR1 udhcpc")

	luci.http.prepare_content("application/json")
	luci.http.write_json("OK")
end

function action_dhcp_skip_timer()
	sys.exec("uci delete dhcpdiscovery.if0.timestamp")
	sys.exec("pkill -USR1 \"dhcpc -p /var/run/udhcpc-if0.pid\"")

	luci.http.prepare_content("application/json")
	luci.http.write_json("OK")
end

function action_dhcp_start_server()
        local result = require('overthebox').create_dhcp_server()
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function action_update_conf()
        local result = require('overthebox').update_confmwan()
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
end

