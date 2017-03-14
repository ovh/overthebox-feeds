#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :

import sys
import os
from swconfig_otb.sw import Sw
from swconfig_otb.config import UCI_NAME, MODEL, CPU_PORT, PORTS, VLANS

def _usage():
    sys.exit("%s dev <dev> (help|load <config>|show)" % os.path.basename(sys.argv[0]))

def _help():
    print(
        "{sw_name}: {sw_name}({sw_type}), ports: {sw_ports} (cpu @ {sw_cpu_port}), vlans: {sw_vlans}"
    ).format(sw_name=UCI_NAME, sw_type=MODEL, sw_ports=PORTS, sw_cpu_port=CPU_PORT, sw_vlans=VLANS)

def _show():
    pass

def _load(args):
    with Sw() as switch:
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
