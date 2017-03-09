#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :

import serial
import config
import re

class State:
    def __init__(self, name, prompt_needle):
        self.name           = name
        self.prompt_needle  = prompt_needle

class States:
    PRESS_ANY_KEY   = State("Press any key",    "Press any key to continue")
    USER_MAIN       = State("User prompt",      "> ")
    ADMIN_MAIN      = State("Admin prompt",     "# ")
    CONFIG          = State("Config",           "(config)# ")
    CONFIG_VLAN     = State("Config VLAN",      "(config-vlan)# ")
    CONFIG_IF       = State("Config IF",        "(config-if)# ")
    CONFIG_IF_RANGE = State("Config IF Range",  "(config-if-range)# ")
    LOGIN_USERNAME  = State("Login (username)", "Username: ")
    LOGIN_PASSWORD  = State("Login (password)", "Password: ")
    MORE            = State("More",             "--More--")


class Sw(serial.Serial):
    def __init__(self):
        serial.Serial.__init__(self)

        self.port=config.port
        self.baudrate=config.baudrate
        self.bytesize=config.bytesize
        self.parity=config.parity
        self.stopbits=config.stopbits
        self.timeout=config.timeout
        self.write_timeout=config.write_timeout
        self.inter_byte_timeout=config.inter_byte_timeout

        self.state = None
        self.hostname = None
        self.last_out = None
        self.last_comments = None

        self.open()

    def recv(self, auto_more):
        self.last_out, self.last_comments = self._recv()

        # If we're now in a more, ask for MOOOORE to get the full output! :p
        while auto_more and self.state == States.MORE:
            self.write(" ") # Sending a space gives us more lines than a LF
            out, comments = self._recv()
            self.last_out.extend(out)
            self.last_comments.extend(comments)

        return (self.last_out, self.last_comments)

    def _recv(self):
        # First, call self.readlines().
        # It reads from serial port and gets a list with one line per list item.
        # In each of the list's item, remove any \r or \n, but only at end of line (right strip)
        # For each line of the output, give it to _filter_comments
        # This will filter out comments and put them in a separated list
        # Finally, use filter(None, list) remove empty elements
        comments = []
        out = filter(None, [self._filter_comments(l.rstrip("\r\n"), comments) for l in self.readlines()])

        self.state = self._parse_prompt(out)
        if self.state:
            print("Switch state is: '%s'" % (self.state.name))
        else:
            print("Switch state is unknown")

        return (out, comments)

    # Filter out all comments and push them in a separated list
    @staticmethod
    def _filter_comments(line, comments):
        # Comments example (always end by CRLF, but sometimes after prompt, sometimes on a new line)
        #   *Jan 13 2000 11:25:20: %System-5: New console connection for user admin, source async  ACCEPTED
        #   *Jan 13 2000 11:32:10: %Port-5: Port gi6 link down
        #   *Jan 13 2000 11:32:13: %Port-5: Port gi4 link up

        # This regex matches a switch comment
        m = re.search(r'(\*.*: %.*: .*)', line)

        # If we've found a comment, move it to a dedicated list
        if m and m.group():
            comments.append(m.group())
            line = line[:m.span()[0]]

        return line

    # Send an arbitrary string to the switch and get the answer
    # If bypass_echo_check is True, the echo will be part of the global answer
    # Otherwise it'll be consumed char by char and will be checked
    # If auto_more is True, if there's a --More--, we'll keep asking for MOOORE and get the full output :p
    # Otherwise the More logic is disabled and --More-- will be received in the output
    # It will be up to the caller to deal with the fact that we're still in a More state
    def _send(self, string, bypass_echo_check=True, auto_more=False):
        # When sending a command, it's safer to send it char by char, and waiting for the echo
        # Why? Try to connect to the switch, go to the Username: prompt.
        # Then, in order to simulate high speed TX, copy "admin" and paste it inside the console
        # The echo arrives in a random order. The behaviour is completely unreliable
        for char in string:
            self.write(char)

            # If we don't care about echo, don't consume and don't check it
            if bypass_echo_check:
                continue

            # Skip Carriage Return (we never send CR, the switch always echo with CR)
            echo = self.read(1)
            echo = echo if echo != "\r" else self.read(1)

            # Each character we get should be the echo of what we just sent
            # '*' is added as exception here for password echo ('*' is the correct echo for password)
            # If we encounter wrong echo, maybe we just got a garbage line from the switch
            # In that case we flush the input buffer so that we stop reading the garbage immediately
            # That way, the next time we read one character, it should be again our echo
            # TODO: We should only tolerate a given fixed "wrong echo budget"
            # Note that in password echo at the end, there is also a "\n" echo which is considered correct
            expected = '*' if self.state == States.LOGIN_PASSWORD and echo != char else char
            if echo != expected:
                print("Invalid echo: expected %c, got %c" % (expected, echo))
                self.flushInput()

        return self.recv(auto_more)

    # Send a command to the switch and get the output
    def send_cmd(self, cmd):
        return self._send("%s\n" % (cmd), False, True)

    # This method takes you from known or unknown state and brings you to "hostname# " prompt
    # If necessary, it will escape an ongoing "--More--". If necessary, it will login.
    def _goto_admin_main_prompt(self):
        self.flushInput()

        # We don't know where we are, let's find out :)
        if self.state in [None, States.PRESS_ANY_KEY]:
            # Because we don't know where we are, we don't know if our keystroke will produce an echo or not
            # So when sending our keystroke, we disable the consumption and check of the echo
            # This allows us to analyze the full answer ourselves and then determine the state
            out, _ = self._send("\n")
            if not out:
                print("Didn't get any answer when trying to determine switch state.")
                return False

        #Now, we know where we are. Let's go to the ADMIN_MAIN state :)
        ok = None

        # We are already where we want to go. Stop here
        if self.state == States.ADMIN_MAIN:
            return True

        if self.state == States.MORE:
            print("Sending one ETX (CTRL+C) to escape --More-- state")
            ok, _ = self._send("\x03")

        # We are logged in and at the "hostname> " prompt. Let's enter "hostname# " prompt
        elif self.state == States.USER_MAIN:
            ok, _ = self.send_cmd("enable")

        # We're logged in and in some menus. Just exit them
        elif self.state in [States.CONFIG, States.CONFIG_VLAN,
                States.CONFIG_IF, States.CONFIG_IF_RANGE]:
            ok, _ = self.send_cmd("end")

        # We're in the login prompt. Just login now!
        elif self.state in [States.LOGIN_USERNAME, States.LOGIN_PASSWORD]:
            ok = self._login()

        # Only return true if we succeeded to bring the switch to the ADMIN_MAIN state
        return ok and self.state == States.ADMIN_MAIN

    # This method analyzes the received output to determine the switch state
    def _parse_prompt(self, out):
        first_line, last_line = out[0], out[-1]

        # States without hostname information in the prompt
        for s in [States.LOGIN_USERNAME, States.LOGIN_PASSWORD]:
            if last_line.startswith(s.prompt_needle):
                return s

        for s in [States.PRESS_ANY_KEY, States.MORE]:
            if last_line == s.prompt_needle:
                return s

        # Hostname determination
        if not self.hostname and not self._determine_hostname(last_line):
            return None

        # States containing the hostname in the prompt
        for s in [States.CONFIG, States.CONFIG_VLAN, States.CONFIG_IF,
                  States.CONFIG_IF_RANGE, States.ADMIN_MAIN, States.USER_MAIN]:
            if last_line.startswith(self.hostname + s.prompt_needle):
                return s

        # Unknown state
        return None

    def _determine_hostname(self, output_last_line):
        m = re.search(r'(?P<hostname>[^(]+).*(?:>|#) ', output_last_line)
        if m and m.group('hostname'):
            self.hostname = m.group('hostname')
            print "Hostname '%s' detected" % (self.hostname)
            return True
        else:
            print "Unable to determine hostname :'("
            return False

    # _login attempts to login to the switch
    # It can only be called when we are in the LOGIN_USERNAME or LOGIN_PASSWORD state
    def _login(self):
        if self.state == States.LOGIN_USERNAME:
            out, _ = self.send_cmd(config.user)
            # The switch rejects us immediately if the username doesn't exist
            if any("Incorrect User Name" in l for l in out):
                print("The switch claims the username is invalid. Check that the credentials are correct.")
                return False

            # We should have entered password state as soon as correct username has been sent
            if self.state != States.LOGIN_PASSWORD:
                print("Unexpected error after sending username to the switch: we should have entered password state")
                return False
            # If we got here, the login has been accepted. Let's continue and send the password below

        # There are 2 possible execution flows:
        #  1) We've just sent the login above, now it's time to send the password
        #  2) We arrive directly here as the first if above was skipped
        # This second case is rare but could occur if the switch's state is the following before launching swconfig:
        # (Username fully typed in but no Line Feed entered)
        #  Username: admin
        # In this case we'll transition from UNKNOWN to LOGIN_PASSWORD state directly
        if self.state == States.LOGIN_PASSWORD:
            out, comments = self.send_cmd(config.password)
            if any("ACCEPTED" in c for c in comments):
                return True

            if any("REJECTED" in c for c in comments):
                print("The switch rejected the password. Check that the credentials are correct.")
                return False

            # It's strange to get here. We succeeded to send the password, but we didn't get ACCEPTED nor REJECTED
            print("Unexpected error after sending password to the switch: no ACCEPTED nor REJECTED found")
            return False

        # What? Have I been called in a state that is not LOGIN_USERNAME nor LOGIN_PASSWORD?
        print("Login method should never have been called now. Bye bye...")
        assert False
