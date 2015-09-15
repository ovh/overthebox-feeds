-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

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

        local mArray = {}

	-- Parse mptcp kernel info
	local mptcp = {}
	local fullmesh = ut.trim(sys.exec("cat /proc/net/mptcp_fullmesh"))
	local hand
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
			if wanName ~= "tun0" then
	                        local wanInterfaceName = ut.trim(sys.exec("uci -p /var/state get network." .. wanName .. ".ifname"))
        	                        if wanInterfaceName == "" then
	                                        wanInterfaceName = "X"
	                                end
	                        local wanDeviceLink = ntm:get_interface(wanInterfaceName)
	                                wanDeviceLink = wanDeviceLink and wanDeviceLink:get_network()
	                                wanDeviceLink = wanDeviceLink and wanDeviceLink:adminlink() or "#"
	                        wansid[wanName] = #mArray.wans + 1
				-- Add multipath info
				local ipaddr	= uci:get("network", wanName, "ipaddr")
				local multipath = "default";
				if ipaddr and mptcp[ipaddr] then
					multipath = uci:get("network", wanName, "multipath") or "on"
				else
					multipath = "off"
				end
				-- Add ping info
				local minping = uci:get("tracker", wanName, "minping")
				local avgping = uci:get("tracker", wanName, "avgping")
				local curping = uci:get("tracker", wanName, "curping")
				-- Return info
	                        mArray.wans[wansid[wanName]] = { name = wanName, link = wanDeviceLink, ifname = wanInterfaceName, ipaddr = ipaddr, multipath = multipath, status = interfaceState, minping = minping, avgping = avgping, curping = curping }
			end
                end
        end

        -- overview status log
--        local mwanLog = ut.trim(sys.exec("logread | grep track | tail -n 50 | sed 'x;1!H;$!d;x'"))
--        if mwanLog ~= "" then
--                mArray.mwanlog = { mwanLog }
--        end

        luci.http.prepare_content("application/json")
        luci.http.write_json(mArray)
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

        result.dhcpservers = {}
        result.mwan3 = {}
        result.user = {}

        uci:foreach("dhcpdiscovery", "lease",
                function (section)
                        result.dhcpservers[section[".name"]] = section
                end
        )

        local dhcpd = require('overthebox').list_running_dhcp()
        uci:foreach("dhcp", "dhcp",
                function (section)
                        if dhcpd[section[".name"]] then
                                result.dhcpservers[section[".name"]] = section
                                result.dhcpservers[section[".name"]].ipaddr = uci:get("network", section[".name"], "ipaddr")
                        end
                end
        )

        local oldchecksum = uci:get("mwan3", "netconfchecksum")
        if oldchecksum then
                local newchecksum = (sys.exec("uci -q export network | md5sum | cut -f1 -d' '"))
                newchecksum = string.sub(newchecksum, 1, 32)
                oldchecksum = string.sub(oldchecksum, 1, 32)
                result.mwan3["new_netconfchecksum"] = newchecksum
                result.mwan3["old_netconfchecksum"] = oldchecksum

                if oldchecksum == newchecksum then
                        result.mwan3["status"] = "uptodate"
                else
                        result.mwan3["status"] = "outofdate"
                end
        end

        result.user["remote_addr"] = luci.http.getenv("REMOTE_ADDR") or ""
        result.user["isFromDhcpLease"] = "false"

        local leases=tools.dhcp_leases()
        for _, value in pairs(leases) do
                if value["ipaddr"] == result.user["remote_addr"] then
                        result.user["isFromDhcpLease"] = "true"
                end
        end

        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
end

function action_activate(service)
	local result = require('overthebox').confirm_service(service)
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
	if tonumber(timestamp) > tonumber(lastcheck) then
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

