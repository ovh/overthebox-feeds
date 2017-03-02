-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
function hex_dump(buf)
  for byte=1, #buf, 16 do
    local chunk = buf:sub(byte, byte+15)
    io.write(string.format('%08X  ',byte-1))
    chunk:gsub('.', function (c) io.write(string.format('%02X ',string.byte(c))) end)
    io.write(string.rep(' ',3*(16-#chunk)))
    io.write(' ',chunk:gsub('%c','.'),"\n")
  end
end

function string:split(sep, max, regex)
  assert(sep ~= '')
  assert(max == nil or max >= 1)

  local record = {}

  if self:len() > 0 then
    local plain = not regex
    max = max or -1

    local field, start = 1, 1
    local first,last = self:find(sep, start, plain)
    while first and max ~= 0 do
      record[field] = self:sub(start, first-1)
      field = field+1
      start = last+1
      first,last = self:find(sep, start, plain)
      max = max-1
    end
    record[field] = self:sub(start)
  end

  return record
end

function string:starts(start)
  return string.sub(self, 1, string.len(start)) == start
end

function string:ends(_end)
  return (_end == '' or string.sub(self, -string.len(_end)) == _end)
end

function table.strfind(table, needle)
  for _, entry in ipairs(table) do
    if string.find(entry, needle) then
      return true
    end
  end
end
