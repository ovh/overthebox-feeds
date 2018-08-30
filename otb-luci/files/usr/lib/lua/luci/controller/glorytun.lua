-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
module("luci.controller.glorytun", package.seeall)

function index()
  entry({"admin", "glorytun", "show"}, call("gt_show")).dependent = false
  entry({"admin", "glorytun", "path"}, call("gt_path")).dependent = false
end

function gt_show()
  local data = {}
  local dump = io.popen("glorytun show")
  if dump then
    for line in dump:lines() do
      local word = string.split(line, " ")
      table.insert(data, {
        dev = word[2],
        pid = tonumber(word[3]),
        bind = { ipaddr = word[4], port = tonumber(word[5]) },
        peer = { ipaddr = word[6], port = tonumber(word[7]) },
        mtu = tonumber(word[8]),
        cipher = word[9]
      })
    end
  end
  luci.http.prepare_content("application/json")
  luci.http.write_json(data)
end

function gt_path()
  local data = {}
  local dump = io.popen("glorytun path")
  if dump then
    for line in dump:lines() do
      local word = string.split(line, " ")
      local info = {
        state = word[2],
        bind = { ipaddr = word[3], port = tonumber(word[4]) },
        public = { ipaddr = word[5], port = tonumber(word[6]) },
        peer = { ipaddr = word[7], port = tonumber(word[8]) },
        mtu = tonumber(word[9]),
        rtt = tonumber(word[10]),
        rttvar = tonumber(word[11]),
        upload = { current = tonumber(word[12]), max = tonumber(word[13]) },
        download = { current = tonumber(word[14]), max = tonumber(word[15]) },
        output = tonumber(word[16]),
        input = tonumber(word[17])
      }
      -- Get interface name from binded ip
      if (info.bind.ipaddr) then
        local ip_to_itf = luci.sys.exec("ip address show to %s" % info.bind.ipaddr)
        if ip_to_itf then
          info.bind.interface = string.match(ip_to_itf, "scope global (%w+)")
        end
      end
      table.insert(data, info)
    end
  end
  luci.http.prepare_content("application/json")
  luci.http.write_json(data)
end
