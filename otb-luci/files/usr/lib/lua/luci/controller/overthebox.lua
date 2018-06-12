-- Copyright 2018 OVH SAS

module("luci.controller.overthebox", package.seeall)

function index()
  entry({"admin", "overthebox"}, alias("admin", "overthebox", "overview"), "OverTheBox", 10).index = true
  entry({"admin", "overthebox", "overview"}, template("otb_overview"), _("Overview"), 1)
end
