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

    uci_config = uci_to_dict(UCI_CONFIG_FILE)
    vlans_wanted = _uci_dict_to_vlan_dict(uci_config)

    with Sw() as switch:
        vlans_current = switch.parse_vlans()


def _uci_dict_to_vlan_dict(uci_dict):
    if 'switch' not in uci_dict:
        sys.exit("No 'switch' section found in the UCI config")

    switches = uci_dict['switch']
    if not any('name' in d and d['name'] == UCI_NAME for _, d in enumerate(switches)):
        sys.exit("No 'switch' section contained a 'name' key with '%s' in UCI config" % (UCI_NAME))

    vlan_dict = {}

    if 'switch_vlan' not in uci_dict:
        return vlan_dict

    vlans = uci_dict['switch_vlan']

    # Browse each 'switch_vlan' section which has a 'device' key with value UCI_NAME
    uci_vlans = (v for i, v in enumerate(vlans) if 'device' in v and v['device'] == UCI_NAME)
    for uci_vlan in uci_vlans:
        # Skip the switch_vlan section if the keys we care about are missing
        if not ('vlan' in uci_vlan and 'ports' in uci_vlan):
            continue

        try:
            vid, ports = int(uci_vlan['vlan']), uci_vlan['ports'].split()
        except ValueError:
            # Skip this VLAN if we don't understand it (it's not a number)
            print "Skipping strange VID '%s'" % (vid)
            continue

        if vid in vlan_dict:
            print "Skipping duplicate VID %d declaration" % (vid)
            continue

        vlan_dict[vid] = {}

        for port in ports:
            tagged = False

            if port[-1] == 't':
                port = port[:-1]
                tagged = True

            # Add the port to the VLAN in our vlan_dict
            try:
                vlan_dict[vid][int(port)] = tagged
            except ValueError:
                # Skip this port if we don't understand it (it's not a number)
                print "Skipping strange port '%s'" % (port)
                continue

    return vlan_dict

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
