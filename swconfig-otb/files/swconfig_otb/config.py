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

WRITE_TIMEOUT = 1

USER, PASSWORD = "admin", "admin"

UCI_NAME = 'otbv2sw'
