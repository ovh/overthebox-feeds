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
module("luci.controller.admin.overthebox", package.seeall)

function index()
	entry({"admin", "overthebox"}, firstchild(), _("OverTheBox"), 19).index = true

	local e = entry({"admin", "overthebox", "overview"}, template("overthebox/index"), _("Overview"), 1)
	e.sysauth = false

	local e = entry({"admin", "overthebox", "multipath"}, template("overthebox/multipath"), _("Realtime graphs"), 2)
	e.leaf = true
	e.sysauth = false

	local e = entry({"admin", "overthebox", "bandwidth_status"}, call("action_bandwidth_data"))
	e.leaf = true
	e.sysauth = false

	local e = entry({"admin", "overthebox", "interfaces_status"}, call("interfaces_status"))
	e.leaf = true
	e.sysauth = false

        local e = entry({"admin", "overthebox", "lease_overview"}, call("lease_overview"))
        e.leaf = true
        e.sysauth = false

        local e = entry({"admin", "overthebox", "dhcp_status"},  call("dhcp_status"))
	e.leaf = true
        e.sysauth = false

        local e = entry({"admin", "overthebox", "dhcp_recheck"},  call("action_dhcp_recheck"))
	e.leaf = true
	e.sysauth = false

        local e = entry({"admin", "overthebox", "dhcp_skiptimer"},  call("action_dhcp_skip_timer"))
	e.leaf = true
	e.sysauth = false

        local e = entry({"admin", "overthebox", "dhcp_start_server"},  call("action_dhcp_start_server"))
	e.leaf = true
	e.sysauth = false

	local e = entry({"admin", "overthebox", "activate"},  call("action_activate"))
	e.leaf = true
	e.sysauth = false

        entry({"admin", "overthebox", "update_conf"},  call("action_update_conf")).leaf = true

end

-- Multipath overview functions
function interfaces_status()

	local mwan3 	= require("luci.controller.mwan3")
	local ut 	= require "luci.util"
        local ntm 	= require "luci.model.network".init()
	local uci 	= require "luci.model.uci".cursor()
	local json      = require("luci.json")

	local logged	= isLogged()
	local mArray = {}

	-- Overthebox info
	mArray.overthebox = {}
	mArray.overthebox["version"] = require('overthebox')._VERSION
	-- Check that requester is in same network
	mArray.overthebox["local_addr"]		= uci:get("network", "lan", "ipaddr")
	mArray.overthebox["wan_addr"]           = "0.0.0.0"
	local wanaddr = ut.trim(sys.exec("cat /tmp/wanip"))
	if string.match(wanaddr, "^%d+\.%d+\.%d+\.%d+$") then
		if logged then
			mArray.overthebox["wan_addr"] = wanaddr
		else
			mArray.overthebox["wan_addr"] = wanaddr:gsub("^(%d+)%.%d+%.%d+%.(%d+)", "%1.***.***.%2")
		end
	end
	mArray.overthebox["remote_addr"]        = luci.http.getenv("REMOTE_ADDR") or ""
	mArray.overthebox["remote_from_lease"]	= false
        local leases=tools.dhcp_leases()
        for _, value in pairs(leases) do
                if value["ipaddr"] == mArray.overthebox["remote_addr"] then
			mArray.overthebox["remote_from_lease"] = true
			mArray.overthebox["remote_hostname"] = value["hostname"]
                end
        end
	-- Check overthebox service are running
	mArray.overthebox["vtun_service"] = false
	if string.find(sys.exec("/usr/bin/pgrep vtund"), "%d+") then
                mArray.overthebox["vtun_service"] = true
        end
	mArray.overthebox["socks_service"] = false
	if string.find(sys.exec("/usr/bin/pgrep ss-redir"), "%d+") then
		mArray.overthebox["socks_service"] = true
	end
	-- Add DHCP infos by parsing dnsmask config file
	mArray.overthebox.dhcpd = {}
	dnsmasq = ut.trim(sys.exec("cat /var/etc/dnsmasq.conf"))
	for itf, range_start, range_end, mask, leasetime in dnsmasq:gmatch("range=(%w+),(%d+\.%d+\.%d+\.%d+),(%d+\.%d+\.%d+\.%d+),(%d+\.%d+\.%d+\.%d+),(%w+)") do
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
        -- overview status
        local statusString = mwan3.getInterfaceName()
        if statusString ~= "" then
                mArray.wans = {}
                wansid = {}

                for wanName, interfaceState in string.gfind(statusString, "([^%[]+)%[([^%]]+)%]") do
                        local wanInterfaceName = ut.trim(sys.exec("uci -p /var/state get network." .. wanName .. ".ifname"))
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
			if wanName == "tun0" then
				mArray.overthebox["vtund"] = { label = wanLabel, name = wanName, link = wanDeviceLink, ifname = wanInterfaceName, ipaddr = ipaddr, multipath = multipath, status = interfaceState }
			else
				-- Add ping info
				data = json.decode(ut.trim(sys.exec("cat /tmp/tracker/if/" .. wanName)))
				local minping = "NaN"
				local avgping = "NaN"
				local curping = "NaN"
				local wanip   = "0.0.0.0"
				local whois   = "Unknown provider"
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
				end
	                        mArray.wans[wansid[wanName]] = { label = wanLabel, name = wanName, link = wanDeviceLink, ifname = wanInterfaceName, ipaddr = ipaddr, gateway = gateway, multipath = multipath, status = interfaceState, minping = minping, avgping = avgping, curping = curping, wanip = wanip, whois = whois }
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

	for _, dev in luci.util.vspairs(luci.sys.net.devices()) do
		if dev ~= "lo" then
                	if uci:get("network", dev, "multipath") == "on" then
				result[dev] = "[" .. string.gsub((luci.sys.exec("luci-bwc -i %q 2>/dev/null" % dev)), '[\r\n]', '') .. "]"
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

-- DHCP overview functions
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
	if result == true then
		action_dhcp_start_server()
		action_dhcp_recheck()
	end
	luci.http.prepare_content("application/json")
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

