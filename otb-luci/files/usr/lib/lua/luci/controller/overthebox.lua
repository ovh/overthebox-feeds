-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
module("luci.controller.overthebox", package.seeall)

function index()
  entry({"admin", "overthebox"}, alias("admin", "overthebox", "overview"), "OverTheBox", 10).index = true
  entry({"admin", "overthebox", "overview"}, template("otb_overview"), "Overview", 1)
  entry({"admin", "overthebox", "qos"}, cbi("otb_qos"), "QoS", 2)
  entry({"admin", "overthebox", "activate"}, call("otb_activate")).dependent = false
end

function otb_activate()
  local dump = io.popen("otb-confirm-service")
  if dump then
    for line in dump:lines() do
      if line == "OK" then
        luci.http.status(200, "OK")
        dump:close()
        return
      end
    end
  end
  luci.http.status(500, "Oups")
end
