# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 :
"""OTBv2 Switch module, extension for VLANs

This module adds methods to the class Sw, all related to VLAN management
"""

import logging
import swconfig_otb.config as config

logger = logging.getLogger('swconfig')

def update_vlan_conf(self, vlans_wanted, ports_wanted):
    vlans_current, ports_current = self._parse_vlans()
    logger.debug("Wanted VLANs: %s", vlans_wanted)
    logger.debug("Wanted interfaces configuration %s", ports_wanted)

    logger.debug("Current VLANs: %s", vlans_current)
    logger.debug("Current interfaces configuration %s", ports_current)

    added, removed = self._set_diff(vlans_current, vlans_wanted)
    logger.debug("VIDs Added: %s", added)
    logger.debug("VIDs Removed: %s", removed)

    changed, same = self._dict_diff(ports_current, ports_wanted)
    logger.debug("IFs Changed: %s", changed)
    logger.debug("IFs Same: %s", same)

def _parse_vlans(self):
    """Ask the switch its VLAN state and return it

    Returns:
        A set and a dictionary of dictionary.
        - The set just contains all the existing VIDs on the switch.
        - For the dict: first dict layer has the interface number as key.
            The second layer has two keys: 'untagged' and 'tagged'.
                Key 'untagged': the value is either None or only one VID value
                Key 'tagged': the value is a set of VID this interface belongs to
    """
    out, _ = self.send_cmd("show vlan static")

    # Initialize our two return values
    vlans, ports = self.init_vlan_config_datastruct()

    # Skip header and the second line (-----+-----...)
    for line in out[2:]:
        row = [r.strip() for r in line.split('|')]
        vid, untagged, tagged = int(row[0]), row[2], row[3]

        vlans.add(vid)

        untagged_range = self._str_to_if_range(untagged)
        tagged_range = self._str_to_if_range(tagged)

        for if_ in untagged_range:
            if ports[if_]['untagged'] is None:
                ports[if_]['untagged'] = vid
            else:
                logger.warning("Skipping subsequent untagged VIDs for port %d. " \
                               "Value was %s", if_, ports[if_]['untagged'])

        for if_ in tagged_range:
            ports[if_]['tagged'].add(vid)

    return vlans, ports

@staticmethod
def init_vlan_config_datastruct():
    """Initialize an empty vlan config data structure"""
    vlans = set()
    ports = {key: {'untagged': None, 'tagged': set()} for key in range(1, config.PORTS + 1)}

    return vlans, ports

@staticmethod
def _str_to_if_range(string):
    """Take an interface range string and generate the expanded version in a list.

    Only the interface ranges starting with 'gi' will be taken into account.

    Args:
        string: A interface range string (ex 'gi4,gi6,gi8-10,gi16-18,lag2')

    Returns:
        A list of numbers which is the expansion of the whole range. For example,
            the above input will give [4, 6, 8, 9, 10, 16, 17, 18]
    """
    # Split the string by ','.
    # Exclude elements that don't start with "gi" (we could have 'lag8-15', or '---').
    # Then, remove the 'gi' prefix and split by '-'. We end up with a list of lists.
    # This is a list of the ranges bounds (1 element or 2: start and end bounds).
    # Then, return a list of all the concatenated expanded ranges.
    # The trick of using a[0] and a[-1] allows it to work with single numbers as well.
    # This wouldn't be the case if we had used a[0] and a[1].
    # If there's only one digit [1], it will compute range(1, 1 + 1) which is 1.
    range_ = [r[len('gi'):].split('-') for r in string.split(',') if r.startswith('gi')]
    return [i for r in range_ for i in range(int(r[0]), int(r[-1]) + 1)]

@staticmethod
def _set_diff(old, new):
    intersect = new.intersection(old)
    added = new - intersect
    removed = old - intersect

    return added, removed

@staticmethod
def _dict_diff(old, new):
    set_old, set_new = set(old.keys()), set(new.keys())
    intersect = set_new.intersection(set_old)

    changed = set(o for o in intersect if old[o] != new[o])
    same = set(o for o in intersect if old[o] == new[o])

    return changed, same
