# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :

import serial

PORT = '/dev/ttyS0'
BAUDRATE = 115200
BYTESIZE = serial.EIGHTBITS
PARITY = serial.PARITY_NONE
STOPBITS = serial.STOPBITS_ONE

READ_TIMEOUT = 0.1
INTER_BYTE_TIMEOUT = 0.1
READ_RETRIES = 4
BAD_ECHO_BUDGET = 10

WRITE_TIMEOUT = 1

USER, PASSWORD = "admin", "admin"

UCI_NAME = 'otbv2sw'
MODEL = 'TG-NET S3500-15G-2F'
PORT_MIN = 1
PORT_CPU = 15
PORT_MAX = 18
PORT_COUNT = (PORT_MAX - PORT_MIN) + 1
VID_MAX = 4094
DEFAULT_VLAN = 1
