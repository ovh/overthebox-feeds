-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

local wa = require "luci.tools.webadmin"
--local fs = require "nixio.fs"

m = Map("dscp", translate("Differentiated services"),
	translate("Traffic may be classified by many different parameters, such as source address, destination address or traffic type and assigned to a specific traffic class."))

s = m:section(TypedSection, "classify", translate("Classification Rules"))
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true
s.sortable  = true

p = s:option(ListValue, "proto", translate("Protocol"))
p:value("tcp", "TCP")
--p:value("", translate("all"))
p.default = "tcp"
--p:value("udp", "UDP")
--p:value("icmp", "ICMP")
--p.rmempty = true

ports = s:option(Value, "ports", translate("Ports"))
--ports.rmempty = true
--ports:value("", translate("all"))

--srch = s:option(Value, "srchost", translate("Source host"))
--srch.rmempty = true
--srch:value("", translate("all"))
--wa.cbi_add_knownips(srch)

--dsth = s:option(Value, "dsthost", translate("Destination host"))
--dsth.rmempty = true
--dsth:value("", translate("all"))
--wa.cbi_add_knownips(dsth)

comment = s:option(Value, "comment", translate("Comment"))

t = s:option(ListValue, "class", translate("Class"))
t:value("CS1", translate("CS1 - Scavenger"))
t:value("CS2", translate("CS2 - Normal"))
t:value("CS3", translate("CS3 - Signaling"))
t:value("CS4", translate("CS4 - Realtime"))
t:value("CS5", translate("CS5 - Broadcast video"))
t:value("CS6", translate("CS6 - Network control"))
--t:value("CS7", translate("Reserved"))
t.default = "OAM"


--bytes = s:option(Value, "connbytes", translate("Number of bytes"))


return m
