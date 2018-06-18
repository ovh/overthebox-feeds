-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :

local sys = require "luci.sys"

local m = Map("dscp", "QoS", "")

-- This functions adds known IPs and names to the input value
function ipHelper(input)
  sys.net.host_hints(function(mac, v4, v6, name)
    if v4 then
      input:value(tostring(v4), "%s (%s)" %{ tostring(v4), name or mac })
    end
  end)
end

local s = m:section(TypedSection, "classify", "Packet classification rules", "", "")
s.anonymous = true
s.addremove = true

local direction = s:option(ListValue, "direction", "Direction")
direction.default = "upload"
direction.rmempty = false
direction:value("upload")
direction:value("download")

local proto = s:option(Value, "proto", "Protocol")
proto.default = "all"
proto:value("tcp")
proto:value("udp")
proto:value("icmp")

local sIP = s:option(Value, "src_ip", "Source IP")
sIP.rmempty = true
sIP:value("", "all")
ipHelper(sIP)

local sport = s:option(Value, "src_port", "Source port")
sport.rmempty = true
sport:value("", "all")
sport:depends("proto","tcp")
sport:depends("proto","udp")

local dIP = s:option(Value, "dest_ip", "Destination IP")
dIP.rmempty = true
dIP:value("", "all")
ipHelper(dIP)

local dport = s:option(Value, "dest_port", "Destination port")
dport.rmempty = true
dport:value("", "all")
dport:depends({proto="tcp", direction="upload"})
dport:depends({proto="udp", direction="upload"})

local t = s:option(ListValue, "class", "Class")
t:value("cs0", "Normal")
t:value("cs1", "Low priority")
t:value("cs2", "High priority")
t:value("cs4", "Latency - VoIP")

local comment = s:option(Value, "comment", "Comment")
comment.rmempty = true

return m
