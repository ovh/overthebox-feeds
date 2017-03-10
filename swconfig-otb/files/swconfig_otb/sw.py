# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :
"""OTBv2 Switch module

This module implements primitives to serially interact with the TG-NET S3500-15G-2F switch.
"""

import re
import serial
import config

class _State(object):
    def __init__(self, name, prompt_needle):
        self.name = name
        self.prompt_needle = prompt_needle

class _States(object):
    PRESS_ANY_KEY = _State("Press any key", "Press any key to continue")
    USER_MAIN = _State("User prompt", "> ")
    ADMIN_MAIN = _State("Admin prompt", "# ")
    CONFIG = _State("Config", "(config)# ")
    CONFIG_VLAN = _State("Config VLAN", "(config-vlan)# ")
    CONFIG_IF = _State("Config IF", "(config-if)# ")
    CONFIG_IF_RANGE = _State("Config IF Range", "(config-if-range)# ")
    LOGIN_USERNAME = _State("Login (username)", "Username: ")
    LOGIN_PASSWORD = _State("Login (password)", "Password: ")
    MORE = _State("More", "--More--")

class Sw(object): # pylint: disable=R0903
    """Represent a serial connection to a TG-NET S3500-15G-2F switch."""

    def __init__(self):
        self.sock = serial.Serial()

        self.sock.port = config.port
        self.sock.baudrate = config.baudrate
        self.sock.bytesize = config.bytesize
        self.sock.parity = config.parity
        self.sock.stopbits = config.stopbits
        self.sock.timeout = config.timeout
        self.sock.write_timeout = config.write_timeout
        self.sock.inter_byte_timeout = config.inter_byte_timeout

        self.state = None
        self.hostname = None
        self.last_out = None
        self.last_comments = None

        self.sock.open()

    def _recv(self, auto_more):
        """Receive everything. If needed, we'll ask the switch for MOOORE. :p

        Some commands may activate a pager when the answer becomes too big.
        We would then stay stuck with a --More-- at the bottom.
        This method receives output as many times as needed and gather the whole output.
        """
        self.last_out, self.last_comments = self._recv_once()

        # If we're now in a more, ask for MOOOORE to get the full output! :p
        while auto_more and self.state == _States.MORE:
            self.sock.write(" ") # Sending a space gives us more lines than a LF
            out, comments = self._recv_once()
            self.last_out.extend(out)
            self.last_comments.extend(comments)

        return (self.last_out, self.last_comments)

    def _recv_once(self):
        """Receive once, filter output and update switch state by parsing prompt"""
        # First, call self.readlines().
        # It reads from serial port and gets a list with one line per list item.
        # In each of the list's item, remove any \r or \n, but only at end of line (right strip)
        # For each line of the output, give it to _filter
        # This will filter out switch comments and put them into a separated list
        # Finally, use filter(None, list) to remove empty elements
        coms = []
        out = filter(None, [self._filter(l.rstrip("\r\n"), coms) for l in self.sock.readlines()])

        self.state = self._parse_prompt(out)
        if self.state:
            print "Switch state is: '%s'" % (self.state.name)
        else:
            print "Switch state is unknown"

        return (out, coms)

    @staticmethod
    def _filter(line, comments):
        """Remove comments and push them to a separated list

        Comments always end by CRLF, sometimes after prompt, sometimes on a new line
        They start with a '*' and a date in the form '*Jan 13 2000 11:25:20: '
        Then come a type prefix and the message:
            %System-5: New console connection for user admin, source async  ACCEPTED
            %Port-5: Port gi6 link down
            %Port-5: Port gi4 link up

        Args:
            line: The current line being processed
            comments: A reference to a list where we can push the comments we find

        Returns:
            The modified output line (it can become empty if the whole line was a comment)
        """
        # This regex matches a switch comment
        comment_regex = re.search(r'(\*.*: %.*: .*)', line)

        # If we've found a comment, move it to a dedicated list
        if comment_regex and comment_regex.group():
            comments.append(comment_regex.group())
            line = line[:comment_regex.span()[0]]

        return line

    def _send(self, string, bypass_echo_check=True, auto_more=False):
        """Send an arbitrary string to the switch and get the answer

        Args:
            string: The string to send to the switch
            bypass_echo_check: When True, the echo will be part of the global answer
                Otherwise it'll be consumed char by char and will be checked
            auto_more: When true, we'll keep asking for more and get the full output
                Otherwise the More logic is disabled and --More-- will be received in the output
                It will be up to the caller to deal with the fact that we're still in a More state
        """
        # When sending a command, it's safer to send it char by char, and wait for the echo
        # Why? Try to connect to the switch, go to the Username: prompt.
        # Then, in order to simulate high speed TX, copy "admin" and paste it inside the console.
        # The echo arrives in a random order. The behaviour is completely unreliable.
        for char in string:
            self.sock.write(char)

            # If we don't care about echo, don't consume and don't check it
            if bypass_echo_check:
                continue

            # Skip Carriage Return (we never send CR, the switch always echo with CR)
            echo = self.sock.read(1)
            echo = echo if echo != "\r" else self.sock.read(1)

            # Each character we get should be the echo of what we just sent
            # '*' is also considered to be a good password echo
            # If we encounter wrong echo, maybe we just got a garbage line from the switch
            # In that case we flush the input buffer so that we stop reading the garbage immediately
            # That way, the next time we read one character, it should be again our echo
            # TODO: We should only tolerate a given fixed "wrong echo budget"
            # Note: In password echo at the end, there is a "\n" echo which is considered correct
            expected = '*' if self.state == _States.LOGIN_PASSWORD and echo != char else char
            if echo != expected:
                print "Invalid echo: expected %c, got %c" % (expected, echo)
                self.sock.flushInput()

        return self._recv(auto_more)

    def send_cmd(self, cmd):
        """Send a command to the switch, check the echo and get the full output.

        Args:
            cmd: The command to send. Do not add any LF at the end.

        Returns:
            A tuple (out, comments)
                out: List of strings of the regular output (no comments inside)
                comments: List of strings of the switch comments
        """
        return self._send("%s\n" % (cmd), False, True)

    def _goto_admin_main_prompt(self):
        """Bring the switch to the known state "hostname# " prompt (from known or unknown state)

        If necessary, it will login, exit some menus, escape an ongoing "--More--"...
        """
        self.sock.flushInput()

        # We don't know where we are, let's find out :)
        if self.state in [None, _States.PRESS_ANY_KEY]:
            # We don't know where we are: we don't know if our keystroke will produce an echo or not
            # So when sending our keystroke, we disable the consumption and check of the echo
            # This allows us to analyze the full answer ourselves and then determine the state
            out, _ = self._send("\n")
            if not out:
                print "Didn't get any answer when trying to determine switch state."
                return False

        #Now, we know where we are. Let's go to the ADMIN_MAIN state :)
        res = None

        # We are already where we want to go. Stop here
        if self.state == _States.ADMIN_MAIN:
            return True

        if self.state == _States.MORE:
            print "Sending one ETX (CTRL+C) to escape --More-- state"
            res, _ = self._send("\x03")

        # We are logged in and at the "hostname> " prompt. Let's enter "hostname# " prompt
        elif self.state == _States.USER_MAIN:
            res, _ = self.send_cmd("enable")

        # We're logged in and in some menus. Just exit them
        elif self.state in [_States.CONFIG, _States.CONFIG_VLAN,
                            _States.CONFIG_IF, _States.CONFIG_IF_RANGE]:
            res, _ = self.send_cmd("end")

        # We're in the login prompt. Just login now!
        elif self.state in [_States.LOGIN_USERNAME, _States.LOGIN_PASSWORD]:
            res = self._login()

        # Only return true if we succeeded to bring the switch to the ADMIN_MAIN state
        return res and self.state == _States.ADMIN_MAIN

    def _parse_prompt(self, out):
        """Analyze the received output to determine the switch state

        Args:
            out: A list with the output that we'll use to determine the state

        Returns:
            A state if we found out, or None if we still don't known where we are
        """
        last_line = out[-1]

        # States without hostname information in the prompt
        for state in [_States.LOGIN_USERNAME, _States.LOGIN_PASSWORD]:
            if last_line.startswith(state.prompt_needle):
                return state

        for state in [_States.PRESS_ANY_KEY, _States.MORE]:
            if last_line == state.prompt_needle:
                return state

        # Hostname determination
        if not self.hostname and not self._determine_hostname(last_line):
            return None

        # States containing the hostname in the prompt
        for state in [_States.CONFIG, _States.CONFIG_VLAN, _States.CONFIG_IF,
                      _States.CONFIG_IF_RANGE, _States.ADMIN_MAIN, _States.USER_MAIN]:
            if last_line.startswith(self.hostname + state.prompt_needle):
                return state

        # Unknown state
        return None

    def _determine_hostname(self, output_last_line):
        """Extract the hostname from the prompt and store it"""
        hostname_regex = re.search(r'(?P<hostname>[^(]+).*(?:>|#) ', output_last_line)
        if hostname_regex and hostname_regex.group('hostname'):
            self.hostname = hostname_regex.group('hostname')
            print "Hostname '%s' detected" % (self.hostname)
            return True
        else:
            print "Unable to determine hostname :'("
            return False

    # It can only be called when we are in the LOGIN_USERNAME or LOGIN_PASSWORD state
    def _login(self):
        """Automatically login into the switch

        Only call me if we are in the LOGIN_USERNAME or LOGIN_PASSWORD state.
        """
        if self.state == _States.LOGIN_USERNAME:
            out, _ = self.send_cmd(config.user)
            # The switch rejects us immediately if the username doesn't exist
            if any("Incorrect User Name" in l for l in out):
                print "The switch claims the username is invalid. " \
                      "Check that the credentials are correct."
                return False

            # We should have entered password state as soon as correct username has been sent
            if self.state != _States.LOGIN_PASSWORD:
                print "Unexpected error after sending username to the switch: " \
                      "we should have entered password state"
                return False
            # If we got here, the login has been accepted. Let's continue and send the password

        # There are 2 possible execution flows:
        #  1) We've just sent the login above, now it's time to send the password
        #  2) We arrive directly here as the first if above was skipped
        # This 2th case is rare but could occur if the state is following before launching swconfig:
        # (Username fully typed in but no Line Feed entered)
        #  Username: admin
        # In this case we'll transition from UNKNOWN to LOGIN_PASSWORD state directly
        if self.state == _States.LOGIN_PASSWORD:
            out, comments = self.send_cmd(config.password)
            if any("ACCEPTED" in c for c in comments):
                return True

            if any("REJECTED" in c for c in comments):
                print "The switch rejected the password. Check that the credentials are correct."
                return False

            print "Unexpected error after sending password: no ACCEPTED nor REJECTED found"
            return False

        # What? Have I been called in a state that is not LOGIN_USERNAME nor LOGIN_PASSWORD?
        print "Login method should never have been called now. Bye bye..."
        assert False
