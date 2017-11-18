-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

local uci = luci.model.uci.cursor()

local wa = require "luci.tools.webadmin"
local ut = require "luci.util"
local sys = require "luci.sys"

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
	direction:value("download")

proto = s:option(Value, "proto", translate("Protocol"))
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
	dsth:depends("direction", "upload")
	wa.cbi_add_knownips(dsth)

dports = s:option(Value, "dest_port", translate("Destination ports"))
	dports.rmempty = true
	dports:value("", translate("all"))
	dports:depends({proto="tcp", direction="upload"})
	dports:depends({proto="udp", direction="upload"})

t = s:option(ListValue, "class", translate("Class"))
	t:value("cs0", translate("Normal"))
	t:value("cs1", translate("Low priority"))
	t:value("cs2", translate("High priority"))
	t:value("cs4", translate("Latency - VoIP"))

comment = s:option(Value, "comment", translate("Comment"))

return m
