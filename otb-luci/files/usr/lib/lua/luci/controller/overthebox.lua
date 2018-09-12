-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
module("luci.controller.overthebox", package.seeall)

function index()
  entry({"admin", "overthebox"}, alias("admin", "overthebox", "overview"), "OverTheBox", 10).index = true
  entry({"admin", "overthebox", "overview"}, template("otb_overview"), "Overview", 1)
  entry({"admin", "overthebox", "dhcp"}, cbi("otb_dhcp"), "DHCP", 2)
  entry({"admin", "overthebox", "dns"}, cbi("otb_dns"), "DNS", 3)
  entry({"admin", "overthebox", "routing"}, cbi("otb_routing"), "Routing", 4)
  entry({"admin", "overthebox", "qos"}, cbi("otb_qos"), "QoS", 5)

  entry({"admin", "overthebox", "confirm_service"}, call("otb_confirm_service")).dependent = false
  entry({"admin", "overthebox", "time"}, call("otb_time")).dependent = false
  entry({"admin", "overthebox", "dhcp_leases_status"}, call("otb_dhcp_leases_status")).dependent = false

  entry({"admin", "overthebox", "data"}, call("otb_get_data")).dependent = false
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

function _readr(src)
   local dst = {}
   local type = nixio.fs.stat(src, "type")
   if type == "dir" then
      for file in nixio.fs.dir(src) do
         dst[file] = _readr(src..'/'..file);
      end
   elseif type == "reg" then
      local dataFile = io.open(src, "r")
      if dataFile then
         data = dataFile:read("*line")
         dst = luci.jsonc.parse(data) or data
         dataFile:close()
      end
   end
   return dst
end

function otb_get_data()
   local dataPath = "/tmp/otb-data"
   local result   = {}
   if nixio.fs.access(dataPath) then
      result = _readr(dataPath);
   end
   luci.http.prepare_content("application/json")
   luci.http.write_json(result)
end
