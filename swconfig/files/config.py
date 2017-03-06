# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :

import serial

port='/dev/ttyS0'
baudrate=115200
bytesize=serial.EIGHTBITS
parity=serial.PARITY_NONE
stopbits=serial.STOPBITS_ONE
timeout=1000
write_timeout=100
inter_byte_timeout=10
