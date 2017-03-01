rs232 = require("luars232")

local MAX_HOSTNAME_LEN = 20
local SERIAL_TIMEOUT   = 100

-- Switch class definition
Switch = {}

Switch.State = {
    PRESS_ANY_KEY   = {},
    USER_MAIN       = {},
    ADMIN_MAIN      = {},
    CONFIG          = {},
    CONFIG_VLAN     = {},
    CONFIG_IF       = {},
    CONFIG_IF_RANGE = {},
    LOGIN_USERNAME  = {},
    LOGIN_PASSWORD  = {},
    UNKNOWN         = {},
}

function Switch:new(file, username, password)
    local s = {}
    setmetatable(s, self)
    self.__index = self

    s.baud = rs232.RS232_BAUD_115200
    s.bits = rs232.RS232_DATA_8
    s.parity = rs232.RS232_PARITY_NONE
    s.flow = rs232.RS232_FLOW_OFF
    s.stop_bits = rs232.RS232_STOP_1

    s.file = file
    s.sock = nil
    s.hostname = nil
    s.state = Switch.State.UNKNOWN
    s.username = username
    s.password = password
    return s
end

function Switch:open()
    if sock ~= nil then
        return false
    end

    if self:_file_is_busy() then
        self:_print_error("'" .. self.file .. "' is busy")
        return false
    end

    local err, sock = rs232.open(self.file)
    if err ~= rs232.RS232_ERR_NOERROR then
        self._print_error("Unable to connect to the switch", err)
        return false
    end

    sock:set_baud_rate(self.baud)
    sock:set_data_bits(self.bits)
    sock:set_parity(self.parity)
    sock:set_flow_control(self.flow)
    sock:set_stop_bits(self.stop_bits)

    self.sock = sock
    self:_print_rs232_state()
    return true
end

function Switch:close()
    if self.sock ~= nil then
        self.sock:close()
        self.sock = nil
    end
end

function Switch:_file_is_busy()
    fd = io.popen("lsof " .. self.file)
    line_number = #fd:read("*a")
    fd:close()
    return (line_number > 0)
end

function Switch:_print_rs232_state()
    print(string.format("%s\n", tostring(self.sock)))
end

function Switch:_print_error(msg, err)
    if err == nil then
        print(msg)
    else
        print(string.format("%s: %s\n", msg, rs232.error_tostring(err)))
    end
end

function Switch:_data_to_table(data)
    data = string.split(data, "\r\n")
    -- Sometimes the last line is empty (because of data ending by an additional \r\n)
    -- In this case we pop the last line which is empty, as we don't want it
    -- For example, this is the case for the message 'Press any key to continue'
    if #data > 1 and data[#data] == "" then
        table.remove(data)
    end

    return data
end

function Switch:send(cmd)
    if not self:_send(cmd) then
        return nil
    end

    data = self:_recv()

    if data == nil then
        return nil
    end

    hex_dump(data)

    data = self:_data_to_table(data)
    self.state = self:_parse_prompt(data)

    return data
end

function Switch:_read_one_char()
    err, data, len = self.sock:read(1, SERIAL_TIMEOUT, 0)

    if err ~= rs232.RS232_ERR_NOERROR or len ~= 1 then
        self:_print_error("Error while reading one char", err)
        return nil
    end

    return data
end

function Switch:_send(cmd)
    -- When sending a command, only append a Line Feed
    cmd = cmd .. "\n"

    for i = 1, #cmd do
        char = string.sub(cmd, i, i)
        -- TODO: Check write error
        self.sock:write(char, SERIAL_TIMEOUT)

        -- This serial connection works in terminal mode
        -- We should get an echo of every character we enter
        char_echo = self:_read_one_char()
        if not char_echo then
            return false
        end

        -- Filter out Carriage Return characters
        if char_echo == "\r" then
            char_echo = self:_read_one_char()
            if not char_echo then
                return false
            end
        end

        if char ~= char_echo and char_echo ~= '*' then
            print(string.format("'%s' != '%s'", char, char_echo))
            self.sock:flush()
        end
    end

    return true
end

function Switch:_recv()
    res = ""
    while true do
        err, data, len = self.sock:read(1, SERIAL_TIMEOUT, 0)

        if err ~= rs232.RS232_ERR_NOERROR or len == 0 then
            break
        end
        res = res .. data
    end

    if res:len() == 0 then
        return nil
    end

    -- TODO: Handle the --More--

    return res
end

function Switch:_parse_prompt(data)
    last_line = data[#data]

    if string.starts(last_line, "Username: ") then
        print("State Username detected")
        return Switch.State.LOGIN_USERNAME

    elseif string.starts(last_line, "Password: ") then
        print("State Password detected")
        return Switch.State.LOGIN_PASSWORD

    elseif string.starts(last_line, "Press any key to continue") then
        print("State 'Press any key' detected")
        return Switch.State.PRESS_ANY_KEY
    end

    -- Determine the hostname
    if self.hostname == nil then
        -- '%' is the lua escape character for pattern, because '(' otherwise would have another meaning
        needles = {"%(", "# ", "> "}
        for key, needle in ipairs(needles) do
            hostname_end = string.find(last_line, needle)
            if hostname_end and hostname_end > 1 and hostname_end <= MAX_HOSTNAME_LEN + 1 then
                self.hostname = string.sub(last_line, 1, hostname_end - 1)
                break
            end
        end
        if not self.hostname then
            self:_print_error("Unexpected error: hostname could not be determined.")
            return Switch.State.UNKNOWN
        else
            print("Hostname has been determined: " .. self.hostname)
        end
    end

    if string.starts(last_line, self.hostname .. "(config)# ") then
        print("State Config detected")
        return Switch.State.CONFIG

    elseif string.starts(last_line, self.hostname .. "(config-vlan)# ") then
        print("State Config VLAN detected")
        return Switch.State.CONFIG_VLAN

    elseif string.starts(last_line, self.hostname .. "(config-if)# ") then
        print("State Config IF detected")
        return Switch.State.CONFIG_IF

    elseif string.starts(last_line, self.hostname .. "(config-if-range)# ") then
        print("State Config IF Range detected")
        return Switch.State.CONFIG_IF_RANGE

    elseif string.starts(last_line, self.hostname .. "# ") then
        print("State Admin main detected")
        return Switch.State.ADMIN_MAIN

    elseif string.starts(last_line, self.hostname .. "> ") then
        print("State User main detected")
        return Switch.State.USER_MAIN
    else
        print("Unknown state :'(")
        return Switch.State.UNKNOWN
    end

    hex_dump(last_line)
end

function Switch:_goto_admin_main()
    local ok

    self.sock:flush()

    -- Sorry about this loop... Actually we never loop except when state is unknown
    -- Is there a better way, avoiding infinite loops, gotos and recursive calls?
    while true do
        if self.state == Switch.State.ADMIN_MAIN then
            ok = true
            break
        elseif self.state == Switch.State.USER_MAIN then
            ok = self:send("enable")
            break
        elseif self.state == Switch.State.CONFIG or
                self.state == Switch.State.CONFIG_VLAN or
                self.state == Switch.State.CONFIG_IF or
                self.state == Switch.State.CONFIG_IF_RANGE then
            ok = self:send("end")
            break
        elseif self.state == Switch.State.LOGIN_USERNAME or
                self.state == Switch.State.LOGIN_PASSWORD then
            ok = self:_login()
            break
        elseif self.state == Switch.State.UNKNOWN or self.state == Switch.State.PRESS_ANY_KEY then
            -- TODO check write error here
            self.sock:write("\n", SERIAL_TIMEOUT)

            -- We need to use low level receive here because of the "Username:" exception
            -- just after the "Press any key to continue" where we can't check the echo of the "\n"
            data = self:_recv()
            if data ~= nil then
                -- Remove leading "\n" if there is one (our echo most of the time, but not for Username: )
                if #data > 1 and data[1] == "\n" then
                    data = string.sub(data, 2, -1)
                end
                self.state = self:_parse_prompt(self:_data_to_table(data))
                ok = true
                -- Don't break here. We want to loop again as state has been updated
            else
                ok = false
                break
            end
        end
    end

    return ok and self.state == Switch.State.ADMIN_MAIN
end

function Switch:_login()
    if self.state == Switch.State.LOGIN_USERNAME then
        print("I need to enter my username dude...")
        -- We should have entered password state as soon as username has been sent
        if not self:send(self.username) or self.state ~= Switch.State.LOGIN_PASSWORD then
            return false
        end
    end

    if self.state == Switch.State.LOGIN_PASSWORD then
        print("I need to enter my password dude...")
        data = self:send(self.password)
        if data == nil then
            return false
        end

        -- If we find the string ACCEPTED in the output, login is successful!
        if table.strfind(data, "ACCEPTED") then
            return true
        end
    end

    return false
end
