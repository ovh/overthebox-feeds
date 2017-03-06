#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :

import serial
import config

from collections import OrderedDict

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

        self.open()
