#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :
"""swconfig CLI emulation

This emulates the swconfig CLI, but instead of communicating with the switch using kernel driver,
we connect to the switch via a serial connection.
"""

import sys
import os

from swconfig_otb.sw import Sw
from swconfig_otb.uci import uci_to_dict
from swconfig_otb.config import UCI_NAME, MODEL, CPU_PORT, PORTS, VLANS

UCI_CONFIG_FILE = 'network'

def _usage():
    sys.exit("%s dev <dev> (help|load <config>|show)" % os.path.basename(sys.argv[0]))

def _help():
    print(
        "{name}: {name}({type_}), ports: {ports} (cpu @ {cpu_port}), vlans: {vlans}"
    ).format(name=UCI_NAME, type_=MODEL, ports=PORTS, cpu_port=CPU_PORT, vlans=VLANS)

def _show():
    pass

def _load(args):
    if len(args) != 2:
        _usage()

    if args[1] != UCI_CONFIG_FILE:
        sys.exit("Sorry, only '%s' is supported for the config file" % (UCI_CONFIG_FILE))

    with Sw() as switch:
        uci_config = uci_to_dict(UCI_CONFIG_FILE)
        vlans_current = switch.parse_vlans()

def _cli():
    if len(sys.argv) < 4:
        _usage()

    if sys.argv[1] != 'dev':
        _usage()

    if sys.argv[2] != UCI_NAME:
        sys.exit("Sorry, '%s' is the only supported device" % (UCI_NAME))

    if sys.argv[3] == 'help':
        _help()
    elif sys.argv[3] == 'load':
        _load(sys.argv[3:])
    elif sys.argv[3] == 'show':
        _show()
    else:
        _usage()

if __name__ == '__main__':
    _cli()
