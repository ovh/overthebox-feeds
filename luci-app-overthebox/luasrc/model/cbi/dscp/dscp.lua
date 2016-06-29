-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

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

ports = s:option(Value, "src_port", translate("Source ports"))
ports.rmempty = true
ports:value("", translate("all"))

dsth = s:option(Value, "dest_ip", translate("Destination host"))
dsth.rmempty = true
dsth:value("", translate("all"))
wa.cbi_add_knownips(dsth)

ports = s:option(Value, "dest_port", translate("Destination ports"))
ports.rmempty = true
ports:value("", translate("all"))

t = s:option(ListValue, "class", translate("Class"))
t:value("cs1", translate("CS1 - Scavenger"))
t:value("cs2", translate("CS2 - Normal"))
t:value("cs3", translate("CS3 - Signaling"))
t:value("cs4", translate("CS4 - Realtime"))
t:value("cs5", translate("CS5 - Broadcast video"))
t:value("cs6", translate("CS6 - Network control"))
t:value("cs7", translate("CS7 - Reserved"))
t.default = "cs2"

comment = s:option(Value, "comment", translate("Comment"))
--bytes = s:option(Value, "connbytes", translate("Number of bytes"))

return m
