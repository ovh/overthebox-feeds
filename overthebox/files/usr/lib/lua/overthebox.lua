-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :

local require = require
local json    = require "luci.json"
local sys     = require "luci.sys"

local io       = require("io")
local string   = require("string")
local posix    = require("posix")
local sys_stat = require("posix.sys.stat")

local print = print
local ipairs, pairs, next, type, tostring, tonumber = ipairs, pairs, next, type, tostring, tonumber
local table, setmetatable, getmetatable = table, setmetatable, getmetatable

local uci = require("luci.model.uci")
local debug = false

function get_version()
  local file = io.open("/etc/otb-version", "r")
  if not file then return nil end
  local version = file:read("*line")
  file:close()
  return version
end

local VERSION = get_version() or "0.0.0"

module "overthebox"
_VERSION = VERSION

function get_mounts()
  local mounts = {}
  for line in io.lines("/proc/mounts") do
    local t = split(line)
    table.insert(mounts, {device=t[1], mount_point=t[2], fs=t[3], options=t[4]})
  end
  return mounts
end

function checkReadOnly()
  for _, mount in pairs(get_mounts()) do
    if mount.mount_point and mount.mount_point == "/" then
      if mount.options and mount.options:match("^ro") then -- assume ro is always the first of the option
        return true
      end
    end
  end
  return false
end

function split(t)
  local r = {}
  if t == nil then return r end
  for v in string.gmatch(t, "%S+") do
    table.insert(r, v)
  end
  return r
end


-- Mwan conf generator
function update_confmwan()
  local ucic = uci.cursor()
  -- Check if we need to update mwan conf
  local oldmd5 = ucic:get("mwan3", "netconfchecksum")
  local newmd5 = string.match(sys.exec("uci -q export network | egrep -v 'upload|download|trafficcontrol|label' | md5sum"), "[0-9a-f]*")
  if oldmd5 and (oldmd5 == newmd5) then
    log("update_confmwan: no changes !")
    return false, nil
  end
  -- Avoid race condition
  local l = lock("update_confmwan")
  if not l then
    log("Could not acquire lock !")
    return false, nil
  end
  log("Lock on update_confmwan() acquired")
  -- Start main code
  local results={}
  -- clear up mwan config
  ucic:foreach("mwan3", "policy",
  function (section)
    if section["generated"] == "1" and section["edited"] ~= "1" then
      ucic:delete("mwan3", section[".name"])
    end
  end
  )
  ucic:foreach("mwan3", "member",
  function (section)
    if section["generated"] == "1" and section["edited"] ~= "1" then
      ucic:delete("mwan3", section[".name"])
    end
  end
  )
  ucic:foreach("mwan3", "interface",
  function (section)
    if section["generated"] == "1" and section["edited"] ~= "1" then
      ucic:delete("mwan3", section[".name"])
    end
  end
  )
  ucic:foreach("mwan3", "rule",
  function (section)
    if section["generated"] == "1" and section["edited"] ~= "1" then
      ucic:delete("mwan3", section[".name"])
    end
  end
  )
  -- Setup trackers IPs
  local tracking_servers = {}
  table.insert( tracking_servers, "51.254.49.132" )
  table.insert( tracking_servers, "51.254.49.133" )
  local tracking_tunnels = {}
  table.insert( tracking_tunnels, "169.254.254.1" )
  --
  local interfaces={}
  local size_interfaces = 0 -- table.getn( does not work....

  -- Table indexed with dns ips to list reacheable interface for this DNS ip
  local dns_policies = {}

  -- Create a tracker for each mptcp interface
  ucic:foreach("network", "interface",
  function (section)
    if section["multipath"] == "on" or section["multipath"] == "master" or section["multipath"] == "backup" or section["multipath"] == "handover" then
      size_interfaces = size_interfaces + 1
      interfaces[ section[".name"] ] = section
      ucic:set("mwan3", section[".name"], "interface")
      if ucic:get("mwan3", section[".name"], "edited") ~= "1" then
        ucic:set("mwan3", section[".name"], "enabled", "1")
        if next(tracking_servers) then
          ucic:set_list("mwan3", section[".name"], "track_ip", tracking_servers)
        end
        ucic:set("mwan3", section[".name"], "track_method","dns")
        ucic:set("mwan3", section[".name"], "reliability", "1")
        ucic:set("mwan3", section[".name"], "count", "1")
        ucic:set("mwan3", section[".name"], "timeout", "3")
        ucic:set("mwan3", section[".name"], "interval", "5")
        ucic:set("mwan3", section[".name"], "down", "3")
        ucic:set("mwan3", section[".name"], "up", "6")
      end
      ucic:set("mwan3", section[".name"], "generated", "1")
      if section["dns"] then
        local seen = {}
        for dns in string.gmatch(section["dns"], "%S+") do
          if seen[dns] == nil then
            if dns_policies[dns] == nil then
              dns_policies[dns] = {}
            end
            seen[dns] = section[".name"]
            table.insert(dns_policies[dns], section[".name"])
          end
        end
      end
    elseif section["type"] == "tunnel" then
      size_interfaces = size_interfaces + 1
      interfaces[section[".name"]] = section
      -- Create a tracker used to monitor tunnel interface
      ucic:set("mwan3", section[".name"], "interface")
      if ucic:get("mwan3", section[".name"], "edited") ~= "1" then
        ucic:set("mwan3", section[".name"], "enabled", "1")
        if next(tracking_tunnels) then
          ucic:set_list("mwan3", section[".name"], "track_ip", tracking_tunnels) -- No tracking ip for tunnel interface
        end
        ucic:set("mwan3", section[".name"], "track_method","icmp")
        ucic:set("mwan3", section[".name"], "reliability", "1")
        ucic:set("mwan3", section[".name"], "count", "1")
        ucic:set("mwan3", section[".name"], "timeout", "3")
        ucic:set("mwan3", section[".name"], "interval", "5")
        ucic:set("mwan3", section[".name"], "down", "3")
        ucic:set("mwan3", section[".name"], "up", "6")
      end
      ucic:set("mwan3", section[".name"], "generated", "1")
    elseif section[".name"] == "tun0" then
      size_interfaces = size_interfaces + 1
      interfaces[section[".name"]] = section
      -- Create a tun0 tracker used for non tcp traffic
      ucic:set("mwan3", "tun0", "interface")
      if ucic:get("mwan3", "tun0", "edited") ~= "1" then
        ucic:set("mwan3", "tun0", "enabled", "1")
        if next(tracking_tunnels) then
          ucic:set_list("mwan3", "tun0", "track_ip", tracking_tunnels) -- No tracking ip for tunnel interface
        end
        ucic:set("mwan3", section[".name"], "track_method","icmp")
        ucic:set("mwan3", "tun0", "reliability", "1")
        ucic:set("mwan3", "tun0", "count", "1")
        ucic:set("mwan3", "tun0", "timeout", "3")
        ucic:set("mwan3", "tun0", "interval", "5")
        ucic:set("mwan3", "tun0", "down", "3")
        ucic:set("mwan3", "tun0", "up", "6")
      end
      ucic:set("mwan3", "tun0", "generated", "1")
    end
  end
  )
  -- generate all members
  local members = {}

  local members_wan = {}
  local members_tun = {}
  local members_qos = {}

  local list_interf = {}
  local list_wan    = {}
  local list_tun    = {}
  local list_qos    = {}

  -- sorted iterator to sort interface by metric
  function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
      table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex, function (a, b)
      return tonumber(interfaces[a].metric or 0) < tonumber(interfaces[b].metric or 0)
    end )
    return orderedIndex
  end

  function orderedNext(t, state)
    key = nil
    if state == nil then
      t.__orderedIndex = __genOrderedIndex( t )
      key = t.__orderedIndex[1]
    else
      for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
          key = t.__orderedIndex[i+1]
        end
      end
    end
    if key then
      return key, t[key]
    end
    t.__orderedIndex = nil
    return
  end

  function sortByMetric(t)
    return orderedNext, t, nil
  end
  -- create interface members
  for name, interf in sortByMetric(interfaces) do
    log("Creating mwan policy for " .. name)
    for i=1,size_interfaces do
      local metric = i
      -- build policy name
      local name = interf[".name"].."_m"..metric.."_w1"
      if not members[metric] then
        members[metric] = {}
      end
      if not list_interf[metric] then
        list_interf[metric] =  {}
      end
      -- parc type of members
      if interf[".name"] == "tun0" then
        if not members_tun[metric] then
          members_tun[metric] = {}
        end
        if not list_tun[metric] then
          list_tun[metric] = {}
        end
        table.insert(members_tun[metric], name)
        table.insert(list_tun[metric], interf[".name"])

      elseif interf["type"] == "tunnel" then
        if not members_qos[metric] then
          members_qos[metric] = {}
        end
        if not list_qos[metric] then
          list_qos[metric] = {}
        end
        table.insert(members_qos[metric], name)
        table.insert(list_qos[metric], interf[".name"])
      elseif interf["multipath"] == "on" or interf["multipath"] == "master" or interf["multipath"] == "backup" or interf["multipath"] == "handover" then
        if not members_wan[metric] then
          members_wan[metric] = {}
        end
        if not list_wan[metric] then
          list_wan[metric] = {}
        end
        table.insert(members_wan[metric], name)
        table.insert(list_wan[metric], interf[".name"])
      end
      -- populating ref tables
      table.insert(members[metric], name)
      table.insert(list_interf[metric], interf[".name"])
      --- Creating mwan3 member
      ucic:set("mwan3", name, "member")
      if ucic:get("mwan3", name, "edited") ~= "1" then
        ucic:set("mwan3", name, "interface", interf[".name"])
        ucic:set("mwan3", name, "metric", metric)
        ucic:set("mwan3", name, "weight", 1)
      end
      ucic:set("mwan3", name, "generated", 1)
    end
  end
  -- generate policies
  if #members_wan and members_wan[1] then
    log("Creating mwan balanced policy")
    ucic:set("mwan3", "balanced", "policy")
    if ucic:get("mwan3", "balanced", "edited") ~= "1" then
      ucic:set_list("mwan3", "balanced", "use_member", members_wan[1])
    end
    ucic:set("mwan3", "balanced", "generated", "1")
  end

  ucic:set("mwan3", "failover_api", "policy")
  if #members_tun and members_tun[1] then
    ucic:set("mwan3", "balanced_tuns", "policy")
    if ucic:get("mwan3", "balanced_tuns", "edited") ~= "1" then
      ucic:set_list("mwan3", "balanced_tuns", "use_member", members_tun[1])
    end
    ucic:set("mwan3", "balanced_tuns", "generated", "1")
    if ucic:get("mwan3", "failover_api", "edited") ~= "1" then
      ucic:set_list("mwan3", "failover_api", "use_member", members_tun[1])
    end
  end

  if #members_qos and members_qos[1] then
    ucic:set("mwan3", "balanced_qos", "policy")
    if ucic:get("mwan3", "balanced_qos", "edited") ~= "1" then
      ucic:set_list("mwan3", "balanced_qos", "use_member", members_qos[1])
    end
    ucic:set("mwan3", "balanced_qos", "generated", "1")
    if ucic:get("mwan3", "failover_api", "edited") ~= "1" then
      ucic:set_list("mwan3", "failover_api", "use_member", members_qos[1])
    end
  end

  if #members_qos and #members_tun and members_qos[1] and members_tun[2] then
    local members_tuns = {}
    for k, v in pairs(members_qos[1]) do
      table.insert(members_tuns, v)
    end
    for k, v in pairs(members_tun[2]) do
      table.insert(members_tuns, v)
    end
    if ucic:get("mwan3", "failover_api", "edited") ~= "1" then
      ucic:set_list("mwan3", "failover_api", "use_member", members_tuns)
    end
  end
  ucic:set("mwan3", "failover_api", "generated", "1")

  -- all uniq policy
  log("Creating mwan single policy")
  for i=1,#list_interf[1] do
    local name = list_interf[1][i].."_only"
    ucic:set("mwan3", name, "policy")
    if ucic:get("mwan3", name, "edited") ~= "1" then
      ucic:set_list("mwan3", name, "use_member", members[1][i])
    end
    ucic:set("mwan3", name, "generated", "1")
  end

  local seenName = { }
  function generate_route(route)
    local my_members = {}
    local my_interf = {}
    local metric=0

    for i=1,#route do
      metric = metric + 1
      table.insert(my_members, members[metric][route[i]])
      table.insert(my_interf, list_interf[metric][route[i]])
    end

    local name = table.concat(my_interf, "_")
    if #my_interf > 3 then
      name = table.concat(my_interf, "", 1, 3)
    end
    if string.len(name) > 15 then
      name = string.sub(name, 1, 15)
    end
    if seenName[name] == nil then
      log("genrating route of " .. name)
      ucic:set("mwan3", name, "policy")
      if ucic:get("mwan3", name, "edited") ~= "1" then
        ucic:set_list("mwan3", name, "use_member", my_members)
      end
      ucic:set("mwan3", name, "generated", "1")
      seenName[name] = my_members
      if first_tun0_policy == nil and string.find(name, '^tun0*') then
        first_tun0_policy=name
      end
    end
  end

  function table_copy(obj, seen)
    if type(obj) ~= 'table' then
      return obj
    end
    if seen and seen[obj] then
      return seen[obj]
    end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do
      res[table_copy(k, s)] = table_copy(v, s)
    end
    return res
  end

  function generate_all_routes(tree, possibities, depth)
    if not possibities or #possibities == 0 then
      generate_route(tree)
    else
      for i=1,#possibities do
        local c = table_copy(possibities)
        table.remove(c, i)
        local d = table_copy(tree)
        table.insert(d, possibities[i])
        generate_all_routes( d, c, depth+1)
      end
    end
  end

  local key_members={}
  local n=0

  for k,v in pairs(members) do
    n=n+1
    key_members[n]=k
  end

  -- Setting rule to forward all non tcp traffic to tun0
  if not ucic:get("mwan3", "all") then
    ucic:set("mwan3", "all", "rule")
    ucic:set("mwan3", "all", "proto", "all")
    ucic:set("mwan3", "all", "sticky", "0")
  end
  if ucic:get("mwan3", "all", "edited") ~= "1" then
    ucic:set("mwan3", "all", "use_policy", "tun0_only")
  end

  if n > 1 then
    if n < 4 then
      generate_all_routes({}, key_members, 0)
    end

    -- Generate failover policy
    ucic:set("mwan3", "failover", "policy")
    local my_members = {}
    if #members_tun then
      for i=1,#members_tun[1] do
        table.insert(my_members, members_tun[i][i])
      end
    end
    if #members_wan then
      for i=1,#members_wan[1] do
        if members_wan[i + #members_tun[1]] then
          table.insert(my_members, members_wan[#my_members + 1][i])
        end
      end
    end
    if ucic:get("mwan3", "failover", "edited") ~= "1" then
      ucic:set_list("mwan3", "failover", "use_member", my_members)
    end
    ucic:set("mwan3", "failover", "generated", "1")
    -- Update "all" policy
    ucic:set("mwan3", "all", "rule")
    ucic:set("mwan3", "all", "proto", "all")
    if ucic:get("mwan3", "all", "edited") ~= "1" then
      ucic:set("mwan3", "all", "use_policy", "failover")
    end
    ucic:set("mwan3", "all", "generated", "1")
    -- Create icmp policies
    ucic:set("mwan3", "icmp", "rule")
    ucic:set("mwan3", "icmp", "proto", "icmp")
    if ucic:get("mwan3", "icmp", "edited") ~= "1" then
      ucic:set("mwan3", "icmp", "use_policy", "failover")
    end
    ucic:set("mwan3", "icmp", "generated", "1")
    -- Create voip policies
    ucic:set("mwan3", "voip", "rule")
    if ucic:get("mwan3", "voip", "edited") ~= "1" then
      ucic:set("mwan3", "voip", "proto", "udp")
      ucic:set("mwan3", "voip", "dest_ip", '91.121.128.0/23')
      ucic:set("mwan3", "voip", "use_policy", "failover")
    end
    ucic:set("mwan3", "voip", "generated", "1")
    -- Create api policies
    ucic:set("mwan3", "api", "rule")
    if ucic:get("mwan3", "api", "edited") ~= "1" then
      ucic:set("mwan3", "api", "proto", "tcp")
      ucic:set("mwan3", "api", "dest_ip", 'api')
      ucic:set("mwan3", "api", "dest_port", '80')
      ucic:set("mwan3", "api", "use_policy", "failover_api")
    end
    ucic:set("mwan3", "api", "generated", "1")
    -- Create DSCPs policies
    -- cs1
    ucic:set("mwan3", "CS1_Scavenger", "rule")
    ucic:set("mwan3", "CS1_Scavenger", "proto", "all")
    ucic:set("mwan3", "CS1_Scavenger", "dscp_class", "cs1")
    if ucic:get("mwan3", "CS1_Scavenger", "edited") ~= "1" then
      ucic:set("mwan3", "CS1_Scavenger", "use_policy", "failover")
    end
    ucic:set("mwan3", "CS1_Scavenger", "generated", "1")
    -- cs2
    ucic:set("mwan3", "CS2_Normal", "rule")
    ucic:set("mwan3", "CS2_Normal", "proto", "all")
    ucic:set("mwan3", "CS2_Normal", "dscp_class", "cs2")
    if ucic:get("mwan3", "CS2_Normal", "edited") ~= "1" then
      ucic:set("mwan3", "CS2_Normal", "use_policy", "failover")
    end
    ucic:set("mwan3", "CS2_Normal", "generated", "1")
    -- cs3
    ucic:set("mwan3", "CS3_Signaling", "rule")
    ucic:set("mwan3", "CS3_Signaling", "proto", "all")
    ucic:set("mwan3", "CS3_Signaling", "dscp_class", "cs3")
    if ucic:get("mwan3", "CS3_Signaling", "edited") ~= "1" then
      ucic:set("mwan3", "CS3_Signaling", "use_policy", "failover")
    end
    ucic:set("mwan3", "CS3_Signaling", "generated", "1")
    -- cs4
    ucic:set("mwan3", "CS4_Realtime", "rule")
    ucic:set("mwan3", "CS4_Realtime", "proto", "all")
    ucic:set("mwan3", "CS4_Realtime", "dscp_class", "cs4")
    if ucic:get("mwan3", "CS4_Realtime", "edited") ~= "1" then
      ucic:set("mwan3", "CS4_Realtime", "use_policy", "failover")
    end
    ucic:set("mwan3", "CS4_Realtime", "generated", "1")
    -- cs5
    ucic:set("mwan3", "CS5_BroadcastVd", "rule")
    ucic:set("mwan3", "CS5_BroadcastVd", "proto", "all")
    ucic:set("mwan3", "CS5_BroadcastVd", "dscp_class", "cs5")
    if ucic:get("mwan3", "CS5_BroadcastVd", "edited") ~= "1" then
      ucic:set("mwan3", "CS5_BroadcastVd", "use_policy", "failover")
    end
    ucic:set("mwan3", "CS5_BroadcastVd", "generated", "1")
    -- cs6
    ucic:set("mwan3", "CS6_NetworkCtrl", "rule")
    ucic:set("mwan3", "CS6_NetworkCtrl", "proto", "all")
    ucic:set("mwan3", "CS6_NetworkCtrl", "dscp_class", "cs6")
    if ucic:get("mwan3", "CS6_NetworkCtrl", "edited") ~= "1" then
      ucic:set("mwan3", "CS6_NetworkCtrl", "use_policy", "failover")
    end
    ucic:set("mwan3", "CS6_NetworkCtrl", "generated", "1")
    -- cs7
    ucic:set("mwan3", "CS7_Reserved", "rule")
    ucic:set("mwan3", "CS7_Reserved", "proto", "all")
    ucic:set("mwan3", "CS7_Reserved", "dscp_class", "cs7")
    if ucic:get("mwan3", "CS7_Reserved", "edited") ~= "1" then
      ucic:set("mwan3", "CS7_Reserved", "use_policy", "failover")
    end
    ucic:set("mwan3", "CS7_Reserved", "generated", "1")
    -- Generate qos failover policy
    if #members_qos and members_qos[1] then
      for i=1,#members_qos[1] do
        local name = list_qos[1][i].."_failover"
        ucic:set("mwan3", name, "policy")
        local my_members = {}
        table.insert(my_members, members_qos[1][i])
        for j=i,#list_wan[1] do
          table.insert(my_members, members_wan[j + 1][j])
        end
        if ucic:get("mwan3", name, "edited") ~= "1" then
          ucic:set_list("mwan3", name, "use_member", my_members)
        end
        ucic:set("mwan3", name, "generated", "1")
        --
        if list_qos[1][i] == "xtun0" then
          -- Update voip and icmp policies
          if ucic:get("mwan3", "voip", "edited") ~= "1" then
            ucic:set("mwan3", "voip", "use_policy", name)
          end
          if ucic:get("mwan3", "icmp", "edited") ~= "1" then
            ucic:set("mwan3", "icmp", "use_policy", name)
          end
          -- Update DSCPs policies
          if ucic:get("mwan3", "CS3_Signaling", "edited") ~= "1" then
            ucic:set("mwan3", "CS3_Signaling", "use_policy", name)
          end
          if ucic:get("mwan3", "CS4_Realtime", "edited") ~= "1" then
            ucic:set("mwan3", "CS4_Realtime", "use_policy", name)
          end
          if ucic:get("mwan3", "CS5_BroadcastVd", "edited") ~= "1" then
            ucic:set("mwan3", "CS5_BroadcastVd", "use_policy", name)
          end
          if ucic:get("mwan3", "CS6_NetworkCtrl", "edited") ~= "1" then
            ucic:set("mwan3", "CS6_NetworkCtrl", "use_policy", name)
          end
          if ucic:get("mwan3", "CS7_Reserved", "edited") ~= "1" then
            ucic:set("mwan3", "CS7_Reserved", "use_policy", name)
          end
        end
      end
    end
  end
  -- Generate DNS policy at top
  local count = 0
  for dns, interfaces in pairs(dns_policies) do
    count = count + 1;
    local members = {};
    for i=1,#interfaces do
      table.insert(members, interfaces[i].."_m1_w1")
    end
    table.insert(members, "tun0_m2_w1")

    ucic:set("mwan3", "dns_p_" .. count, "policy")
    if ucic:get("mwan3", "dns_p_" .. count, "edited") ~= "1" then
      ucic:set_list("mwan3", "dns_p_" .. count, "use_member", members)
      ucic:set("mwan3", "dns_p_" .. count, "last_resort", "default")

      ucic:set("mwan3", "dns_" .. count, "rule")
      if ucic:get("mwan3", "dns_" .. count, "edited") ~= "1" then
        ucic:set("mwan3", "dns_" .. count, "proto", "udp")
        ucic:set("mwan3", "dns_" .. count, "sticky", "0")
        ucic:set("mwan3", "dns_" .. count, "use_policy", "dns_p_" .. count)
        ucic:set("mwan3", "dns_" .. count, "dest_ip", dns)
        ucic:set("mwan3", "dns_" .. count, "dest_port", 53)
      end
      ucic:set("mwan3", "dns_" .. count, "generated", "1")
    end
    ucic:set("mwan3", "dns_p_" .. count, "generated", "1")
    ucic:reorder("mwan3", "dns_" .. count, count - 1)
  end
  -- reorder lasts policies
  ucic:reorder("mwan3", "api", 244)
  ucic:reorder("mwan3", "icmp", 245)
  ucic:reorder("mwan3", "voip", 246)
  ucic:reorder("mwan3", "CS1_Scavenger", 247)
  ucic:reorder("mwan3", "CS2_Normal", 248)
  ucic:reorder("mwan3", "CS3_Signaling", 249)
  ucic:reorder("mwan3", "CS4_Realtime", 250)
  ucic:reorder("mwan3", "CS5_BroadcastVd", 251)
  ucic:reorder("mwan3", "CS6_NetworkCtrl", 252)
  ucic:reorder("mwan3", "CS7_Reserved", 253)
  ucic:reorder("mwan3", "all", 254)

  ucic:set("mwan3", "netconfchecksum", newmd5)
  ucic:save("mwan3")
  ucic:commit("mwan3")
  -- We don't call reload_config here anymore as this is done in hotplug.d/net
  -- Release mwan3 lock
  l:close()
  return result, interfaces
end


-- helpers
function lock(name)
  -- Open fd for appending
  local nixio = require('nixio')
  local oflags = nixio.open_flags("wronly", "creat")
  local file, code, msg = nixio.open("/tmp/" .. name, oflags)

  if not file then
    return file, code, msg
  end

  -- Acquire lock
  local stat
  stat, code, msg = file:lock("tlock")
  if not stat then
    return stat, code, msg
  end

  file:seek(0, "end")

  return file
end

function tc_stats()
  local output = {}
  for line in string.gmatch((sys.exec("tc -s q")), '[^\r\n]+') do
    table.insert(output, line)
  end


  local result = {}
  result["upload"] = {}
  local curdev;
  local curq;
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
        -- print("["..curdev..", "..curq..", "..bytes.. ", "..pkt..", "..dropped..", "..overlimits..", ".. reque .. "]")
        if result["upload"][curq] == nil then
          result["upload"][curq] = {}
        end
        result["upload"][curq][curdev] = { bytes=bytes, pkt=pkt, dropped=dropped, overlimits=overlimits, requeues=reque }
      end
    end
  end

  output = {}
  result["download"] = {}
  local tcstats = json.decode(sys.exec("curl -s --max-time 1 api/qos/tcstats"))
  if tcstats and tcstats.raw_output then

    for line in string.gmatch(tcstats.raw_output, '[^\r\n]+') do
      table.insert(output, line)
    end

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
          -- print("["..curdev..", "..curq..", "..bytes.. ", "..pkt..", "..dropped..", "..overlimits..", ".. reque .. "]")
          if result["download"][curq] == nil then
            result["download"][curq] = {}
          end
          result["download"][curq][curdev] = { bytes=bytes, pkt=pkt, dropped=dropped, overlimits=overlimits, requeues=reque }
        end
      end
    end
  end
  return result
end

function log(msg)
  posix.syslog( posix.LOG_INFO, msg)
end
