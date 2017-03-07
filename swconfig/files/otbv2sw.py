#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :

import serial
import config

class State:
    def __init__(self, needle, goto_main_cmd):
        self.needle = needle
        self.goto_main_cmd = goto_main_cmd

class States:
    PRESS_ANY_KEY   = State("Press any key to continue",    False)
    USER_MAIN       = State("> ",                           "enable")
    ADMIN_MAIN      = State("# ",                           None)
    CONFIG          = State("(config)# ",                   "exit")
    CONFIG_VLAN     = State("(config-vlan)# ",              "end")
    CONFIG_IF       = State("(config-if)# ",                "end")
    CONFIG_IF_RANGE = State("(config-if-range)# ",          "end")
    LOGIN_USERNAME  = State("Username: ",                   False)
    LOGIN_PASSWORD  = State("Password: ",                   False)
    MORE            = State("--More--",                     False)


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
        self.last_out = None
        self.last_comments = None

        self.open()

    def _filter(self, line):
        # TODO: Exclude also switch comments, not only empty lines
        # Comments example (always end by CRLF, but sometimes after prompt, sometimes on a new line)
        #   *Jan 13 2000 11:25:20: %System-5: New console connection for user admin, source async  ACCEPTED
        #   *Jan 13 2000 11:32:10: %Port-5: Port gi6 link down
        #   *Jan 13 2000 11:32:13: %Port-5: Port gi4 link up
        # But keep them in a separate list so we could get information from them if needed
        if not line:
            return False
        return True

    def recv(self, sent):
        # First, call self.readlines().
        # It reads from serial port and gets a list with one line per list item.
        # Then, exclude our echo, but only if it's found in the first line (index 0)
        # In each of the list's item, remove any \r or \n, but only at end of line (right strip)
        # Finally, use filter(_filter, list) to filter out empty elements and switch comments
        # We end up with one nice filtered list, and the switch comments are separated in dedicated list
        return filter(self._filter, [l.rstrip("\r\n") for i, l in enumerate(self.readlines())
            if i != 0 or l.rstrip("\r\n") != sent.rstrip("\n")])

    def _send(self, string, bypass_echo_check=False):
        # When sending a command, it's safer to send it char by char, and waiting for the echo
        # Why? Try to connect to the switch, go to the Username: prompt.
        # Then, in order to simulate high speed TX, copy "admin" and paste it inside the console
        # The echo arrives in a random order. The behaviour is completely unreliable
        echo=""
        for char in string:
            self.write(char)

            # If we don't care about echo, don't consume and don't check it
            if bypass_echo_check:
                continue

            # Skip Carriage Return (we never send CR, the switch always echo with CR)
            echo_char = self.read(1)
            echo_char = echo_char if echo_char != "\r" else self.read(1)

            # Check echo
            if echo_char != char:
                print("Invalid echo: expected %c, got %c" % (char, echo_char))
                self.flushInput()

        return self.recv(string)

    def send_cmd(self, cmd):
        return self._send("%s\n" % (cmd))
