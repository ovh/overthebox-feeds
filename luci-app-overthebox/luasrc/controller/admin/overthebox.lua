-- Copyright 2015 OVH <OverTheBox@ovh.net>
-- Simon Lelievre (simon.lelievre@corp.ovh.com)
-- Sebastien Duponcheel <sebastien.duponcheel@ovh.net>
--
-- This file is part of OverTheBox for OpenWrt.
--
--    OverTheBox is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    OverTheBox is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with OverTheBox.  If not, see <http://www.gnu.org/licenses/>
--
-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :

local tools = require "luci.tools.status"
local sys   = require "luci.sys"
local json  = require("luci.json")
local ucic  = uci.cursor()
module("luci.controller.admin.overthebox", package.seeall)

function index()
  -- main menu entry
  entry({"admin", "overthebox"}, firstchild(), _("OverTheBox"), 19).index = true
  -- submenu entries
  entry({"admin", "overthebox", "overview"}, template("overthebox/index"), _("Overview"), 1).leaf = true
  entry({"admin", "overthebox", "dscp"}, cbi("dscp/dscp"), _("DSCP Settings"), 2).leaf = true
  entry({"admin", "overthebox", "register_device"}, template("overthebox/register_device"), _("Register device"), 3).leaf = true
  entry({"admin", "overthebox", "lan_traffic"}, template("overthebox/lan_traffic"), _("LAN Traffic"), 4).leaf = true
  entry({"admin", "overthebox", "multipath"}, template("overthebox/multipath"), _("Realtime graphs"), 5).leaf = true
  entry({"admin", "overthebox", "tunnels"}, template("overthebox/tunnels"), _("TUN graphs"), 6).leaf = true
  entry({"admin", "overthebox", "qos"}, template("overthebox/qos"), _("QoS graphs"), 7).leaf = true
  entry({"admin", "overthebox", "add_interface"}, template("overthebox/add_interface")).leaf = true
  -- functions
  entry({"admin", "overthebox", "qos_stats"}, call("action_qos_data")).leaf = true
  entry({"admin", "overthebox", "lan_traffic_data"}, call("action_lan_traffic_data")).leaf = true
  entry({"admin", "overthebox", "bandwidth_status"}, call("action_bandwidth_data")).leaf = true
  entry({"admin", "overthebox", "interfaces_status"}, call("interfaces_status")).leaf = true
  entry({"admin", "overthebox", "lease_overview"}, call("lease_overview")).leaf = true
  entry({"admin", "overthebox", "ipv6_discover"}, call("ipv6_discover")).leaf = true
  entry({"admin", "overthebox", "dhcp_status"}, call("dhcp_status")).leaf = true
  entry({"admin", "overthebox", "dhcp_recheck"}, call("action_dhcp_recheck")).leaf = true
  entry({"admin", "overthebox", "dhcp_skiptimer"}, call("action_dhcp_skip_timer")).leaf = true
  entry({"admin", "overthebox", "activate_service"}, call("action_activate")).leaf = true
  entry({"admin", "overthebox", "need_activate_service"},  call("need_activate")).leaf = true
  entry({"admin", "overthebox", "activate"}, template("overthebox/index")).leaf = true
  entry({"admin", "overthebox", "passwd"}, post("action_passwd")).leaf = true
  entry({"admin", "overthebox", "new_interface"}, post("new_interface")).leaf = true
end

function new_interface()
  local interface_name = luci.http.formvalue("interface_name")
  local device = luci.http.formvalue("device")
  local protocol = luci.http.formvalue("protocol")

  local stderr  = { "" }

  -- DHCP interface on eth0 is forbidden
  if device == "eth0" and protocol == "dhcp" then
    table.insert(stderr, "Cannot create interface dhcp on eth0")
    luci.template.render("overthebox/add_interface", {
      stderr    = table.concat(stderr, "")
    })
    return
  end

  -- Get the id of the interface to be created
  local id = 1
  while ucic:get("network", "cif"..id) do id = id + 1 end

  ifID = "cif"..id
  ifname = device

  -- If it's a static interface on eth0, configure a macvlan
  if device == "eth0" and protocol == "static" then
    device_mac = sys.exec("tr -d '\n' < /sys/class/net/eth0/address")
    devID = ifID.."_dev"
    ucic:set("network", devID, "device")
    ucic:set("network", devID, "name", ifID)
    ucic:set("network", devID, "ifname", ifname)
    ucic:set("network", devID, "type", "macvlan")
    ifname = ifID
  end

  -- Create the interface
  ucic:set("network", ifID, "interface")
  ucic:set("network", ifID, "ifname", ifname)
  ucic:set("network", ifID, "proto", protocol)
  ucic:set("network", ifID, "label", interface_name)
  ucic:set("network", ifID, "multipath", "on")

  ucic:save("network")
  ucic:commit("network")

  -- Add the interface to the wan firewall zone
  firewall = ucic:get_list("firewall", "wan", "network")
  table.insert(firewall, ifID)
  ucic:set_list("firewall", "wan", "network", firewall)

  ucic:save("firewall")
  ucic:commit("firewall")

  luci.http.redirect(luci.dispatcher.build_url("admin/network/network/"..ifID))
end

function action_passwd()
  local result = {}
  result["status"] = false
  local p1 = luci.http.formvalue("p1")
  local p2 = luci.http.formvalue("p2")
  if p1 and p2 then
    if p1 == p2 then
      result["rcode"] = luci.sys.user.setpasswd("root", p1)
      result["status"] = (result["rcode"] ~= nil and result["rcode"] == 0)
      if result["status"] then
        result["error"] = false
      else
        result["error"] = "Internal error"
      end
    else
      result["status"] = false
      result["error"] = "passwords are not the same"
    end
  else
    result["error"] = "missing arguments"
  end
  luci.http.prepare_content("application/json")
  luci.http.write_json(result)
end

-- Multipath overview functions
function interfaces_status()

  local ut 	= require "luci.util"
  local ntm 	= require "luci.model.network".init()
  local uci 	= require "luci.model.uci".cursor()

  local logged	= isLogged()
  local mArray = {}

  -- Overthebox info
  mArray.overthebox = {}
  mArray.overthebox["version"] = ut.trim(sys.exec("cat /etc/otb-version"))
  -- Check that requester is in same network
  mArray.overthebox["service_addr"]	= uci:get("shadowsocks", "proxy", "server") or "0.0.0.0"
  mArray.overthebox["local_addr"]		= uci:get("network", "lan", "ipaddr")
  mArray.overthebox["wan_addr"]		= "0.0.0.0"

  -- wanaddr
  local f = io.open("/tmp/otb-daemon-headers", "rb")
  if f then
    local content = f:read("*all")
    f:close()
    local ip = string.match(content, "X%-Otb%-Client%-Ip: (%d+%.%d+%.%d+%.%d+)", 0)
    if ip then
      mArray.overthebox["wan_addr"] = ip
    end
  end

  mArray.overthebox["remote_addr"]        = luci.http.getenv("REMOTE_ADDR") or ""
  mArray.overthebox["remote_from_lease"]	= false
  local leases=tools.dhcp_leases()
  for _, value in pairs(leases) do
    if value["ipaddr"] == mArray.overthebox["remote_addr"] then
      mArray.overthebox["remote_from_lease"] = true
      mArray.overthebox["remote_hostname"] = value["hostname"]
    end
  end
  -- Check overthebox service are running
  mArray.overthebox["tun_service"] = false
  if string.find(sys.exec("/usr/bin/pgrep '^(/usr/sbin/)?glorytun(-udp)?$'"), "%d+") then
    mArray.overthebox["tun_service"] = true
  end
  mArray.overthebox["socks_service"] = false
  if string.find(sys.exec("/usr/bin/pgrep ss-redir"), "%d+") then
    mArray.overthebox["socks_service"] = true
  end
  -- Check if OTB is downloading recovery image or test download
  mArray.overthebox["downloading"] = false
  if string.find(sys.exec("/usr/bin/pgrep wget"), "%d+") then
    mArray.overthebox["downloading"] = true
  end
  -- Check if OTB is installing updates
  mArray.overthebox["install_updates"] = false
  if string.find(sys.exec("/usr/bin/pgrep opkg"), "%d+") then
    mArray.overthebox["install_updates"] = true
  end
  -- Add DHCP infos by parsing dnsmask config file
  mArray.overthebox.dhcpd = {}
  dnsmasq = ut.trim(sys.exec("cat /var/etc/dnsmasq.conf*"))
  for itf, range_start, range_end, mask, leasetime in dnsmasq:gmatch("range=[%w,!:-]*set:(%w+),(%d+\.%d+\.%d+\.%d+),(%d+\.%d+\.%d+\.%d+),(%d+\.%d+\.%d+\.%d+),(%w+)") do
    mArray.overthebox.dhcpd[itf] = {}
    mArray.overthebox.dhcpd[itf].interface = itf
    mArray.overthebox.dhcpd[itf].range_start = range_start
    mArray.overthebox.dhcpd[itf].range_end = range_end
    mArray.overthebox.dhcpd[itf].netmask = mask
    mArray.overthebox.dhcpd[itf].leasetime = leasetime
    mArray.overthebox.dhcpd[itf].router = mArray.overthebox["local_addr"]
    mArray.overthebox.dhcpd[itf].ip = mArray.overthebox["local_addr"]
    mArray.overthebox.dhcpd[itf].dns = mArray.overthebox["local_addr"]
  end
  for itf, option, value in dnsmasq:gmatch("option=(%w+),([%w:-]+),(%d+\.%d+\.%d+\.%d+)") do
    if mArray.overthebox.dhcpd[itf] then
      if option == "option:router" or option == "3" then
        mArray.overthebox.dhcpd[itf].router = value
      end
      if option == "option:dns-server" or option == "6" then
        mArray.overthebox.dhcpd[itf].dns = value
      end
    end
  end
  -- Parse mptcp kernel info
  local mptcp = {}
  local fullmesh = ut.trim(sys.exec("cat /proc/net/mptcp_fullmesh"))
  for ind, addressId, backup, ipaddr in fullmesh:gmatch("(%d+), (%d+), (%d+), (%d+\.%d+\.%d+\.%d+)") do
    mptcp[ipaddr] = {}
    mptcp[ipaddr].index = ind
    mptcp[ipaddr].id    = addressId
    mptcp[ipaddr].backup= backup
    mptcp[ipaddr].ipaddr= ipaddr
  end
  -- retrive core temperature
  mArray.overthebox["core_temp"] = sys.exec("cat /sys/devices/platform/coretemp.0/hwmon/hwmon0/temp2_input 2>/dev/null"):match("%d+")
  mArray.overthebox["loadavg"] = sys.exec("cat /proc/loadavg 2>/dev/null"):match("[%d%.]+ [%d%.]+ [%d%.]+")
  mArray.overthebox["uptime"] = sys.exec("cat /proc/uptime 2>/dev/null"):match("[%d%.]+")
  -- overview status
  mArray.wans = {}
  mArray.tunnels = {}

  uci:foreach("network", "interface", function (section)
    local interface = section[".name"]
    local net = ntm:get_network(interface)
    local ipaddr = net:ipaddr()
    local gateway = net:gwaddr()

    if not ipaddr or not gateway then return end

    -- Don't show if0 in the overview
    if interface == "if0" then return end

    local ifname = section['ifname']
    local dataPath = "/tmp/otb-data/" .. interface .. "/"

    local asn
    local asnFile = io.open(dataPath .. "asn", "r")
    if asnFile then
        local json_data = asnFile:read("*all")
        asnFile:close()
        asn = json.decode(json_data) or {}
    end

    local connectivity
    local connectivityFile = io.open(dataPath .. "connectivity", "r")
    if connectivityFile then
        connectivity = connectivityFile:read("*line")
        connectivityFile:close()
    end

    local publicIP = "-"
    local publicIPFile = io.open(dataPath .. "public_ip", "r")
    if publicIPFile then
        publicIP = publicIPFile:read("*line")
        publicIPFile:close()
    end

    local latency = "-"
    local latencyFile = io.open(dataPath .. "latency", "r")
    if latencyFile then
        latency = latencyFile:read("*line")
        latencyFile:close()
    end

    local data = {
      label = section['label'] or interface,
      name = interface,
      link = net:adminlink(),
      ifname = ifname,
      ipaddr = ipaddr,
      gateway = gateway,
      multipath = section['multipath'],
      status = connectivity,
      wanip = publicIP,
      latency = latency,
      whois = asn and asn.as_description or "unknown",
      qos = section['trafficcontrol'],
      download = section['download'],
      upload = section['upload'],
    }

    if section['type'] == "tunnel" then
      table.insert(mArray.tunnels, data);
    else
      table.insert(mArray.wans, data);
    end
  end)

  luci.http.prepare_content("application/json")
  luci.http.write_json(mArray)
end

function isLogged()
  local sid = luci.http.getcookie('sysauth');
  if sid and (require('luci.util').ubus("session", "get", { ubus_rpc_session = sid }) or { }).values then
    return true
  else
    return false
  end
end

function lease_overview()
  local stat = require "luci.tools.status"
  local rv = {
    leases     = stat.dhcp_leases(),
    leases6    = stat.dhcp6_leases(),
    wifinets   = stat.wifi_networks()
  }
  luci.http.prepare_content("application/json")
  luci.http.write_json(rv)
end

function write_qos_cache(data)
  local json_data = json.encode(data)
  local file = io.open( "/tmp/tc_stats", "w" )
  file:write(json_data)
  file:close()
end

function read_qos_cache()
  local data = {}
  local file = io.open( "/tmp/tc_stats", "r" )
  if file then
    local json_data = file:read("*all")
    file:close()
    data = json.decode(json_data) or {}
  end
  return data
end

function get_interface_from_metric(metric)
  -- As a default value, we keep the metric
  local ifname = metric
  ucic:foreach("network", "interface",
    function (interface)
      local a = interface["metric"]
      if ifname == metric and a == tostring(metric) then
        ifname = interface["ifname"]
        return
      end
    end
  )
  return ifname
end

function get_qos_label(qdisc, way)
  local normalPriorityString = "Normal"
  local latencyPriorityString = "Latency - VoIP"
  local lowPriorityString = "Low priority"
  local highPriorityString = "High priority"

  if way == "upload" then
    if qdisc == "Best Effort" then
      return normalPriorityString
    elseif qdisc == "Bulk" then
      return lowPriorityString;
    elseif qdisc == "Video" then
      return highPriorityString;
    elseif qdisc == "Voice" then
      return latencyPriorityString
    end
  end

  if way == "download" then
    if qdisc == "2" then
      return lowPriorityString;
    elseif qdisc == "3" then
      return normalPriorityString;
    elseif qdisc == "4" then
      return highPriorityString;
    elseif qdisc == "5" then
      return latencyPriorityString;
    end
  end
  return qdisc
end

-- copied from the old overthebox.lua lib
function tc_stats()
  local result = {}
  result["upload"] = {}
  local output = {}
  ucic:foreach("network", "interface",
    function (interface)
      if interface["multipath"] == "off" then
        return
      end

      local cakestats = json.decode(sys.exec("tc -s q s dev " .. interface["ifname"] .. " | otb-cake-parser"))
      if cakestats then
        for i,stat in pairs(cakestats) do
          local label = get_qos_label(i, "upload")
          if result["upload"][label] == nil then
            result["upload"][label] = {}
          end
          result["upload"][label][interface["ifname"]] = { bytes=stat["bytes"], pkt=stat["pkts"], dropped=0, overlimits=0, requeues=0 }
        end
      end
    end
  )

  result["download"] = {}
  local tcstats = json.decode(sys.exec("curl -s --max-time 1 api/qos/tcstats"))
  if tcstats and tcstats.raw_output then

    for line in string.gmatch(tcstats.raw_output, '[^\r\n]+') do
      table.insert(output, line)
    end

    local curdev, curq
    for i=1, #output do
      if string.byte(output[i]) ~= string.byte(' ') then
        curdev = nil
        curq = nil
      end
      if string.match(output[i], "dev ([^%s]+)") then
        curdev = string.match(output[i], "dev ([^%s]+)")
      end
      if string.match(output[i], "sfq (%d+)") then
        curq = string.match(output[i], "sfq (%d+)")
      end
      if curdev and curq then
        for bytes, pkt, dropped, overlimits, reque in string.gmatch(output[i], "Sent (%d+) bytes (%d+) pkt %(dropped (%d+), overlimits (%d+) requeues (%d+)") do
          -- Get the metric from the queue number
          -- If the queue is 173, the metric is 17 and the queue number is 3
          local queue_nb = curq % 10
          if queue_nb ~= 0 then
            local metric = (curq - queue_nb)/10
            local ifname = get_interface_from_metric(metric)
            local label = get_qos_label(tostring(queue_nb), "download")
            if result["download"][label] == nil then
              result["download"][label] = {}
            end
            result["download"][label][ifname] = { bytes=bytes, pkt=pkt, dropped=dropped, overlimits=overlimits, requeues=reque }
          end
        end
      end
    end
  end
  return result
end

function action_qos_data()
  local data = read_qos_cache()
  local timestamp = os.time()
  local stats = tc_stats()
  if stats and next(stats) ~= nil then
    data[timestamp] = stats
  end
  -- keep only last minute
  local striped_data = {}
  for k,v in pairs(data) do
    if tonumber(k) > tonumber(timestamp) - 60 then
      striped_data[k] = data[k]
    end
  end
  write_qos_cache(striped_data)
  -- format output
  luci.http.prepare_content("application/json")
  luci.http.write_json(striped_data)
end

function action_lan_traffic_data()
  local result = luci.sys.exec("bandwidth fetch json")
  luci.http.prepare_content("application/json")
  luci.http.write(result)
end

function action_bandwidth_data(dev)
  if dev ~= "all" then
    return require('luci.controller.admin.status').action_bandwidth(dev)
  else
    return multipath_bandwidth()
  end
end

function multipath_bandwidth()
  local result = { };
  local uci = luci.model.uci.cursor()

  result["wans"] = {};
  result["tuns"] = {};

  uci:foreach("network", "interface",
  function (section)
    local interface = section[".name"]
    local dev = section["ifname"]
    if dev ~= "lo" then
      local multipath = section["multipath"]
      if multipath == "on" or multipath == "master" or multipath == "backup" or multipath == "handover" then
        result["wans"][interface] = "[" .. string.gsub((luci.sys.exec("luci-bwc -i %q 2>/dev/null" % dev)), '[\r\n]', '') .. "]"
      elseif section["type"] == "tunnel" then
        result["tuns"][interface] = "[" .. string.gsub((luci.sys.exec("luci-bwc -i %q 2>/dev/null" % dev)), '[\r\n]', '') .. "]"
      end
    end
  end
  )

  luci.http.prepare_content("application/json")
  luci.http.write_json(result)
end

-- copied from the old overthebox.lua lib
function _ipv6_discover()
  local interface = 'eth0'
  local result = {}

  local ra6_list = (sys.exec("rdisc6 -nm " .. interface))
  -- dissect results
  local lines = {}
  local index = {}
  ra6_list:gsub('[^\r\n]+', function(c)
    table.insert(lines, c)
    if c:match("Hop limit") then
      table.insert(index, #lines)
    end
  end)
  local ra6_result = {}
  for k,v in ipairs(index) do
    local istart = v
    local iend = index[k+1] or #lines

    local entry = {}
    for i=istart,iend - 1 do
      local level = lines[i]:find('%w')
      local line = lines[i]:sub(level)

      local param, value
      if line:match('^from') then
        param, value = line:match('(from)%s+(.*)$')
      else
        param, value = line:match('([^:]+):(.*)$')
        -- Capitalize param name and remove spaces
        param = param:gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end):gsub("[%s-]",'')
        param = param:gsub("%.$", '')
        -- Remove text between brackets, seconds and spaces
        value = value:lower()
        value = value:gsub("%(.*%)", '')
        value = value:gsub("%s-seconds%s-", '')
        value = value:gsub("^%s+", '')
        value = value:gsub("%s+$", '')
      end

      if entry[param] == nil then
        entry[param] = value
      elseif type(entry[param]) == "table" then
        table.insert(entry[param], value)
      else
        old = entry[param]
        entry[param] = {}
        table.insert(entry[param], old)
        table.insert(entry[param], value)
      end
    end
    table.insert(ra6_result, entry)
  end
  return ra6_result
end

-- DHCP overview functions
function ipv6_discover()
  local result = _ipv6_discover()

  if type(result) == "table" and #result > 1 then
    if not isLogged() then
      for k,v in ipairs(result) do
        if v.Prefix then
          result[k].Prefix = v.Prefix:gsub(":[%a%d]+:[%a%d]+([:]+/%d+)", ":****:****%1")
        end
      end
    end
  end

  luci.http.prepare_content("application/json")
  luci.http.write_json(result)
end

function dhcp_status()
  local uci = luci.model.uci.cursor()
  local uci_tmp = luci.model.uci.cursor("/tmp/dhcpdiscovery")
  local result = {}
  -- Get alien dhcp list
  result.detected_dhcp_servers = {}
  uci_tmp:foreach("dhcpdiscovery", "lease",
  function (section)
    result.detected_dhcp_servers[section[".name"]] = section
  end
  )
  -- List our DHCP service
  result.running_dhcp_service = {}
  uci:foreach("dhcp", "dhcp",
  function (section)
    if (section["dynamicdhcp"] ~= "0") and (section["ignore"] ~= "1") then
      result.running_dhcp_service[section[".name"]] = section
      result.running_dhcp_service[section[".name"]].ipaddr = uci:get("network", section[".name"], "ipaddr")
    end
  end
  )
  -- Return results
  luci.http.prepare_content("application/json")
  luci.http.write_json(result)
end

function action_activate(service)
  sys.exec("otb-confirm-service")
  action_dhcp_recheck()
  luci.http.prepare_content("application/json")
  luci.http.write_json({})
end

function need_activate()
  local result = { };
  local uci = luci.model.uci.cursor()
  luci.http.prepare_content("application/json")
  if uci:get("overthebox", "me", "needs_activation") == "true" then
    result["active"] = false
  else
    result["active"] = true
  end
  luci.http.write_json(result)
end

function action_dhcp_recheck()
  local uci = luci.model.uci.cursor("/tmp/dhcpdiscovery")
  uci:set("dhcpdiscovery", "if0", "lastcheck", os.time())
  uci:delete("dhcpdiscovery", "if0", "siaddr")
  uci:delete("dhcpdiscovery", "if0", "serverid")

  local timestamp = uci:get("dhcpdiscovery", "if0", "timestamp")
  local lastcheck = uci:get("dhcpdiscovery", "if0", "lastcheck")
  if timestamp and lastcheck and (tonumber(timestamp) > tonumber(lastcheck)) then
    uci:set("dhcpdiscovery", "if0", "timestamp", lastcheck)
  end

  uci:commit("dhcpdiscovery")
  sys.exec("pkill -USR1 udhcpc")

  luci.http.prepare_content("application/json")
  luci.http.write_json("OK")
end

function action_dhcp_skip_timer()
  local uci = luci.model.uci.cursor("/tmp/dhcpdiscovery")
  uci:delete("dhcpdiscovery", "if0", "timestamp")
  uci:commit("dhcpdiscovery")

  sys.exec("pkill -USR1 \"dhcpc -p /var/run/udhcpc-if0.pid\"")

  luci.http.prepare_content("application/json")
  luci.http.write_json("OK")
end
