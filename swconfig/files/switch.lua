-- vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :
rs232 = require("luars232")
utils = require("swconfig.utils")

local MAX_HOSTNAME_LEN              = 20
local SERIAL_READ_ONE_CHAR_TIMEOUT  = 100
local SERIAL_WRITE_ONE_CHAR_TIMEOUT = 100

-- Switch class definition
Switch = {}

-- Yes, this is a way in lua to mimic an enum :'(
-- It works because each value is a memory address that will be unique
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

-- This method instantiates a new Switch object.
-- It doesn't connect to the serial port, only prepares the object
function Switch:new(file, username, password)
  -- Following 3 lines are a way in lua to use OOP :'(
  -- Note that we don't need inheritance feature here
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

-- This opens the serial connection
function Switch:open()
  if sock ~= nil then
    return false
  end

  -- Ask the kernel to see if someone is already using the serial link
  -- Better than a lock we would handle ourselves :)
  if self:_file_is_busy() then
    self:_print_error("'" .. self.file .. "' is busy")
    return false
  end

  local err, sock = rs232.open(self.file)
  if err ~= rs232.RS232_ERR_NOERROR then
    self._print_error("Unable to open the serial connection to the switch", err)
    return false
  end

  sock:set_baud_rate(self.baud)
  sock:set_data_bits(self.bits)
  sock:set_parity(self.parity)
  sock:set_flow_control(self.flow)
  sock:set_stop_bits(self.stop_bits)

  self.sock = sock
  return true
end

-- This closes the serial connection and resets the switch object for reuse
-- It's very important NOT to logout from the switch
-- If we logout 5 times, we get following warning:
--  CLI is restarting too fast
--  Console will be blocked 300 seconsd if you restart CLI less than 90 seconds next time.
--
-- If we logout a sixth time, UART CLI won't respond at all for 5 minutes
--  Console is blocking 300 seconsd
--
-- It seems the best option is NOT to logout. CLI will auto logout after an idle time of 10min
function Switch:close()
  if self.sock ~= nil then
    self.sock:close()
    self.sock = nil
  end

  self.hostname = nil
  self.state = Switch.State.UNKNOWN
end

-- Ask the kernel to see if someone else is already using the serial link
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

-- Convert a string to a table with one line by row and without \r\n
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

-- Send a command to the switch, read back the echo, fetch & return the command result
-- A timeout can be specified. It will be applied only when waiting the first char of the response
-- By response we mean the real response of the command, after our own command echo
-- The timeout allow to give the switch's CPU the time to process the user request
-- If no timeout is specified, we'll use a default (rather short) timeout
function Switch:send(cmd, timeout)
  if not self:_send(cmd) then
    return nil
  end

  data = self:_recv(timeout)

  if data == nil then
    return nil
  end

  hex_dump(data)

  data = self:_data_to_table(data)
  self.state = self:_parse_prompt(data)

  return data
end

-- This is a low level method reading only one character at a time
function Switch:_read_one_char()
  err, data, len = self.sock:read(1, SERIAL_READ_ONE_CHAR_TIMEOUT, 0)

  if err ~= rs232.RS232_ERR_NOERROR or len ~= 1 then
    self:_print_error("Error while reading one char", err)
    return nil
  end

  return data
end

-- This low level method sends a command to the switch and consumes the echo
function Switch:_send(cmd)
  -- When sending a command, only append a Line Feed
  cmd = cmd .. "\n"

  for i = 1, #cmd do
    char = string.sub(cmd, i, i)
    -- TODO: Check write error
    self.sock:write(char, SERIAL_WRITE_ONE_CHAR_TIMEOUT)

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

    -- Each character we get should be the echo of what we just sent
    -- '*' is added as exception here for password echo (it's normal to get the '*' "wrong echo")
    -- If we encounter wrong echo, maybe we just got a garbage line from the switch, for example:
    --  martinsw# *Jan 08 2000 08:19:34: %Port-5: Port gi6 link down
    -- We then flush the write and read buffers, so that we stop reading the garbage line immediately
    -- That way, the next time we read one character, it should be again our echo
    -- TODO: We should only tolerate a given fixed "wrong echo budget"
    if char ~= char_echo and (self.state ~= Switch.State.LOGIN_PASSWORD or char_echo ~= '*') then
      print(string.format("Command echo error: got '%s', expected '%s'", char_echo, char))
      self.sock:flush()
    end
  end

  return true
end

-- Implement serial read without the need to specify a length
-- Read as much bytes as there is
-- We need to do this because the underlying serial lib doesn't handle EOF
-- EOF should be possible because the switch uses one stop bit in its UART implementation
-- But because we don't have any EOF mechanism, we assume there's nothing to read if we hit a timeout error
-- A timeout can be specified. If not specified, default timeout apply.
-- The timeout is only used when waiting for the first char of the response.
-- Once the first char arrived, we become more strict and the timeout becomes the default again
function Switch:_recv(timeout)
  res = ""

  -- When user doesn't specify any timeout, use default value
  if not timeout then timeout = SERIAL_READ_ONE_CHAR_TIMEOUT end

  while true do
    -- Reset the timeout to the default one once the first char has been obtained
    if res:len() == 1 then
      timeout = SERIAL_READ_ONE_CHAR_TIMEOUT
    end

    err, data, len = self.sock:read(1, timeout, 0)

    if err ~= rs232.RS232_ERR_NOERROR or len == 0 then
      break
    end
    res = res .. data
  end

  if res:len() == 0 then
    self:_print_error("Error: No data has been received", err)
    return nil
  end

  -- TODO: Handle the --More--

  return res
end

-- This method analyzes the received output to determine the switch state
function Switch:_parse_prompt(data)
  first_line = data[1]
  last_line = data[#data]

  -- It is crucial below to use "starts" and not "ends" because sometimes, there will be a comment after the prompt
  -- For example:
  --  martinsw# *Jan 08 2000 03:54:00: %System-5: New console connection for user admin, source async  ACCEPTED
  --  There should never be anything BEFORE the prompt
  if string.starts(last_line, "Username: ") then
    print("State Username detected")
    return Switch.State.LOGIN_USERNAME

  elseif string.starts(last_line, "Password: ") then
    print("State Password detected")
    return Switch.State.LOGIN_PASSWORD

    -- Press any key to continue is not the last line but the first one
    --  Press any key to continue
    --  *Jan 08 2000 06:42:48: %System-5: New console connection for user admin, source async  REJECTED
  elseif first_line == "Press any key to continue" then
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
end

-- This method brings the switch from any state to the ADMIN_MAIN state ("hostname# " prompt)
-- No matter what the switch's state is, this should bring us there
-- If needed, it will auto-login or exit some menus to reach the ADMIN_MAIN state
function Switch:_goto_admin_main()
  self.sock:flush()

  -- We don't know where we are, let's find out :)
  if self.state == Switch.State.UNKNOWN or self.state == Switch.State.PRESS_ANY_KEY then
    -- TODO check write error here
    self.sock:write("\n", SERIAL_WRITE_ONE_CHAR_TIMEOUT)

    -- We need to use low level receive here because of the "Username: " exception
    -- just after the "Press any key to continue" where we can't check the echo of the "\n"
    data = self:_recv()
    if data ~= nil then
      -- Remove leading "\n" if there is one (our echo most of the time, but not for "Username: ")
      if #data > 1 and data[1] == "\n" then
        data = string.sub(data, 2, -1)
      end
      -- This will update the state with the freshly received prompt
      self.state = self:_parse_prompt(self:_data_to_table(data))
    else
      self:_print_error("No echo at all when trying to determine switch state. Is the switch dead?")
      return false
    end
  end

  -- Now, we know where we are. It's time to go to the ADMIN_MAIN state :)
  local ok

  -- We are already where we want to go. Stop here
  if self.state == Switch.State.ADMIN_MAIN then
    return true
    -- We are logged in and at the "hostname> " prompt. Let's enter "hostname# " prompt
  elseif self.state == Switch.State.USER_MAIN then
    ok = self:send("enable")
    -- We're logged in and in some menus. Just exit them
  elseif self.state == Switch.State.CONFIG or
    self.state == Switch.State.CONFIG_VLAN or
    self.state == Switch.State.CONFIG_IF or
    self.state == Switch.State.CONFIG_IF_RANGE then
    ok = self:send("end")
    -- We're in the login prompt. Just login now!
  elseif self.state == Switch.State.LOGIN_USERNAME or
    self.state == Switch.State.LOGIN_PASSWORD then
    ok = self:_login()
  end

  -- Only return true if we succeeded to bring the switch to the ADMIN_MAIN state
  return ok and self.state == Switch.State.ADMIN_MAIN
end

-- This function attempts to login
-- It can be called whether we are in the LOGIN_USERNAME or LOGIN_PASSWORD state
-- Never call me if the state is something else
function Switch:_login()
  if self.state == Switch.State.LOGIN_USERNAME then
    print("I need to enter my username dude...")

    -- Send the username to the switch
    ret = self:send(self.username)
    if not ret then
      self:_print_error("Unexpected error when attempting to send the username during the login phase")
      return false
    end

    -- The switch rejects us immediately if the username doesn't exist
    if table.strfind(ret, "Incorrect User Name") then
      self:_print_error("The switch claims the username is invalid. Check that the credentials are correct.")
      return false
    end

    -- We should have entered password state as soon as correct username has been sent
    if self.state ~= Switch.State.LOGIN_PASSWORD then
      self:_print_error("Unexpected error after sending username to the switch: we should have entered password state but it's not the case")
      return false
    end
    -- If we got here, our login was accepted, let's continue and send the password below
  end

  -- There are 2 possible execution flows:
  --  1) We've just sent the login above, now it's time to send the password
  --  2) We arrive directly here as the first if above was skipped
  -- This second case is rare but could occur if the switch's state is the following before launching swconfig:
  -- (Username fully typed in but no Line Feed entered)
  --  Username: admin
  -- In this case we'll transition from UNKNOWN to LOGIN_PASSWORD state directly
  if self.state == Switch.State.LOGIN_PASSWORD then
    print("I need to enter my password dude...")
    -- Send the password to the switch
    data = self:send(self.password)
    if data == nil then
      self:_print_error("Unexpected error when attempting to send the password during the login phase")
      return false
    end

    -- If we find the string ACCEPTED in the output, login is successful!
    if table.strfind(data, "ACCEPTED") then
      return true
    end

    -- This will happen when the password is incorrect
    if table.strfind(data, "REJECTED") then
      self:_print_error("The switch rejected the password. Check that the credentials are correct.")

      -- Here, it's strange because we succeeded to send the password, but we didn't get ACCEPTED nor REJECTED
    else
      self:_print_error("Unexpected error when sending the password during the login phase: no ACCEPTED nor REJECTED")
    end

    return false
  end

  -- Whaaaaat? Have I been called in a state that is not LOGIN_USERNAME nor LOGIN_PASSWORD?
  self:_print_error("Login method should never have been called now. Bye bye...")
  assert(false)
  return false
end
