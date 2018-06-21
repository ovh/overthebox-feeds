-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
module("luci.controller.overthebox", package.seeall)

function index()
  entry({"admin", "overthebox"}, alias("admin", "overthebox", "overview"), "OverTheBox", 10).index = true
  entry({"admin", "overthebox", "overview"}, template("otb_overview"), "Overview", 1)
  entry({"admin", "overthebox", "qos"}, cbi("otb_qos"), "QoS", 2)
  entry({"admin", "overthebox", "confirm_service"}, call("otb_confirm_service")).dependent = false
  entry({"admin", "overthebox", "time"}, call("otb_time")).dependent = false
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
