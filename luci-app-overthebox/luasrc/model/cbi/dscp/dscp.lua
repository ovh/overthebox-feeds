-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

local uci = luci.model.uci.cursor()

local wa = require "luci.tools.webadmin"
local ut = require "luci.util"
local sys = require "luci.sys"

local mud = (uci:get("glorytun", "tun0") == "mud" and uci:get("glorytun", "tun0", "enable") == "1") or (uci:get("glorytun", "xtun0") == "mud" and uci:get("glorytun", "xtun0", "enable") == "1")

m = Map("dscp", translate("Differentiated services"),
	translate("Traffic may be classified by many different parameters, such as source address, destination address or traffic type and assigned to a specific traffic class."))

s = m:section(TypedSection, "classify", translate("Classification Rules"))
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true
s.sortable  = true

function cbiAddProtocol(field)
	local protocols = ut.trim(sys.exec("cat /etc/protocols | grep '\\s# ' | awk '{print $1}' | grep -v '^#' | grep -vw -e 'ip' -e 'tcp' -e 'udp' -e 'icmp' -e 'esp' | grep -v 'ipv6' | sort | tr '\n' ' '"))
	for p in string.gmatch(protocols, "%S+") do
		field:value(p)
	end
end

direction = s:option(ListValue, "direction", translate("Direction"))
	direction.default = "upload"
	direction.rmempty = false
	direction:value("upload")
if mud then
	direction:value("download")
	direction:value("both")
end

--dpi = s:option(Value, "dpi", translate("Service"))
--dpi.rmempty = true
--dpi:depends("direction", "download")
--dpi:value("", translate("Disabled"))

proto = s:option(Value, "proto", translate("Protocol"))
	proto:depends("dpi", "")
	proto.default = "all"
	proto.rmempty = false
	proto:value("tcp")
	proto:value("udp")
	proto:value("all")
	proto:value("ip")
	proto:value("icmp")
	proto:value("esp")
	cbiAddProtocol(proto)

srch = s:option(Value, "src_ip", translate("Source host"))
	srch:depends("dpi", "")
	srch.rmempty = true
	srch:value("", translate("all"))
	wa.cbi_add_knownips(srch)

sports = s:option(Value, "src_port", translate("Source ports"))
	sports.rmempty = true
	sports:value("", translate("all"))
	sports:depends("proto","tcp")
	sports:depends("proto","udp")

dsth = s:option(Value, "dest_ip", translate("Destination host"))
	dsth.rmempty = true
	dsth:value("", translate("all"))
if mud then
	dsth:depends("direction", "upload")
end
	wa.cbi_add_knownips(dsth)

dports = s:option(Value, "dest_port", translate("Destination ports"))
	dports.rmempty = true
	dports:value("", translate("all"))
if mud then
	dports:depends({proto="tcp", direction="upload"})
	dports:depends({proto="udp", direction="upload"})
else
	dports:depends("proto","tcp")
	dports:depends("proto","udp")
end

t = s:option(ListValue, "class", translate("Class"))
	t:value("cs1", translate("CS1 - Scavenger"))
	t:value("cs2", translate("CS2 - Normal"))
	t:value("cs3", translate("CS3 - Signaling"))
	t:value("cs4", translate("CS4 - Realtime"))
	t:value("cs5", translate("CS5 - Broadcast video"))
	t:value("cs6", translate("CS6 - Network control"))
	t:value("cs7", translate("CS7 - Reserved"))
	--t:value("drop", translate("Drop"))
	t.default = "cs2"

comment = s:option(Value, "comment", translate("Comment"))
--bytes = s:option(Value, "connbytes", translate("Number of bytes"))

return m
