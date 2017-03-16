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
from swconfig_otb.config import UCI_NAME, MODEL, CPU_PORT, PORTS, DEFAULT_VLAN, VLANS

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
    vlans_wanted, ports_wanted = _uci_dict_to_vlan_conf(uci_config)

    print 'Wanted vlans and interface configuration:'
    print vlans_wanted
    print ports_wanted
    print

    with Sw() as switch:
        vlans, ports = switch.parse_vlans()
        print 'Current vlans and interface configuration:'
        print vlans
        print ports

def _uci_dict_to_vlan_conf(uci_dict):
    if 'switch' not in uci_dict:
        sys.exit("No 'switch' section found in the UCI config")

    switches = uci_dict['switch']
    if not any('name' in d and d['name'] == UCI_NAME for _, d in enumerate(switches)):
        sys.exit("No 'switch' section contained a 'name' key with '%s' in UCI config" % (UCI_NAME))

    vlans, ports = Sw.init_vlan_config_datastruct()

    if 'switch_vlan' not in uci_dict:
        return _vlan_conf_final_pass(vlans, ports)

    uci_vlans = uci_dict['switch_vlan']

    # Browse each 'switch_vlan' section which has a 'device' key with value UCI_NAME
    uci_vlans = (v for i, v in enumerate(uci_vlans) if 'device' in v and v['device'] == UCI_NAME)
    for uci_vlan in uci_vlans:
        # Skip the switch_vlan section if the keys we care about are missing
        if not ('vlan' in uci_vlan and 'ports' in uci_vlan):
            continue

        try:
            uci_vid, uci_ports = int(uci_vlan['vlan']), uci_vlan['ports'].split()
        except ValueError:
            # Skip this VLAN if we don't understand it (it's not a number)
            print "Skipping strange VID '%s'" % (uci_vid)
            continue

        if uci_vid in vlans:
            print "Skipping duplicate VID %d declaration" % (uci_vid)
            continue

        vlans.add(uci_vid)

        for uci_port in uci_ports:
            tagged = False

            if uci_port[-1] == 't':
                uci_port = uci_port[:-1]
                tagged = True

            try:
                uci_port = int(uci_port)
            except ValueError:
                # Skip this port if we don't understand it (it's not a number)
                print "Skipping strange port '%s'" % (uci_port)
                continue

            if tagged:
                ports[uci_port]['tagged'].add(uci_vid)
            else:
                ports[uci_port]['untagged'] = uci_vid

    return _vlan_conf_final_pass(vlans, ports)

def _vlan_conf_final_pass(vlans, ports):
    # Make a final pass on all unassigned ifs, assign them to the default VLAN (untagged)
    # This is what the switch would do as well
    for if_ in [k for k, v in ports.iteritems() if v['untagged'] is None and not v['tagged']]:
        print 'Assigning if %d to default VLAN %d as if was not found in UCI' % (if_, DEFAULT_VLAN)
        ports[if_]['untagged'] = DEFAULT_VLAN

    # Always consider the DEFAULT_VLAN exists as it can't be deleted anyway
    vlans.add(DEFAULT_VLAN)

    return vlans, ports

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
