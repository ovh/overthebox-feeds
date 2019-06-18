-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
module("luci.controller.overthebox", package.seeall)

function index()
  entry({"admin", "overthebox"}, alias("admin", "overthebox", "overview"), "OverTheBox", 10).index = true
  entry({"admin", "overthebox", "overview"}, template("otb_overview"), "Overview", 1)
  entry({"admin", "overthebox", "dhcp"}, cbi("otb_dhcp"), "DHCP", 2)
  entry({"admin", "overthebox", "dns"}, cbi("otb_dns"), "DNS", 3)
  entry({"admin", "overthebox", "routing"}, cbi("otb_routing"), "Routing", 4)
  entry({"admin", "overthebox", "qos"}, cbi("otb_qos"), "QoS", 5)
  entry({"admin", "overthebox", "multipath"}, cbi("otb_multipath"), "Multipath", 6)
	entry({"admin", "overthebox", "realtime"}, alias("admin", "overthebox", "realtime", "connections"), _("Realtime Graphs"), 7)

  entry({"admin", "overthebox", "confirm_service"}, call("otb_confirm_service")).dependent = false
  entry({"admin", "overthebox", "time"}, call("otb_time")).dependent = false
  entry({"admin", "overthebox", "dhcp_leases_status"}, call("otb_dhcp_leases_status")).dependent = false

	entry({"admin", "overthebox", "realtime", "bandwidth"}, template("graph/bandwidth"), _("Traffic"), 1).leaf = true
	entry({"admin", "overthebox", "realtime", "bandwidth_status"}, call("action_bandwidth")).leaf = true

	entry({"admin", "overthebox", "realtime", "connections"}, template("graph/connections"), _("Connections"), 2).leaf = true
	entry({"admin", "overthebox", "realtime", "connections_status"}, call("action_connections")).leaf = true

	entry({"admin", "overthebox", "realtime", "load"}, template("graph/load"), _("Load"), 3).leaf = true
	entry({"admin", "overthebox", "realtime", "load_status"}, call("action_load")).leaf = true

	entry({"admin", "overthebox", "realtime", "status", "nameinfo"}, call("action_nameinfo")).leaf = true
end

function otb_confirm_service()
  local service = luci.http.formvalue("service") or ""
  if os.execute("otb-confirm-service "..service) then
    luci.http.status(200, "OK")
  else
    luci.http.status(500, "ERROR")
  end
end

function otb_time()
  luci.http.prepare_content("application/json")
  luci.http.write_json({ timestamp = tostring(os.time()) })
end

function otb_dhcp_leases_status()
  local s = require "luci.tools.status"
  luci.http.prepare_content("application/json")
  luci.http.write_json(s.dhcp_leases())
end

function action_load()
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -l 2>/dev/null")
	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

function action_connections()
	local sys = require "luci.sys"

	luci.http.prepare_content("application/json")

	luci.http.write('{ "connections": ')
	luci.http.write_json(sys.net.conntrack())

	local bwc = io.popen("luci-bwc -c 2>/dev/null")
	if bwc then
		luci.http.write(', "statistics": [')

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end

	luci.http.write(" }")
end

function action_nameinfo(...)
  local util = require "luci.util"

  luci.http.prepare_content("application/json")
  luci.http.write_json(util.ubus("network.rrdns", "lookup", {
    addrs = { ... },
    timeout = 5000,
    limit = 1000
  }) or { })
end

function action_bandwidth(iface)
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -i %s 2>/dev/null"
		% luci.util.shellquote(iface))

	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

