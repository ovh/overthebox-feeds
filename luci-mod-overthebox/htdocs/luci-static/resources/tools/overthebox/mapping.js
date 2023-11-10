'use strict';
'require uci';

// This is an adaptation of luci-mod-status port status view
// https://github.com/openwrt/luci/pull/5918
// If you encounter issues with complex VLAN topology you may need to integrate resolveVLANchain logic

// Some tools to map uci data
function isString(v) {
    return typeof (v) === 'string' && v !== '';
}

return L.Class.extend({
    mapVLAN: function (mapping) {
        const bridge_vlans = uci.sections('network', 'bridge-vlan'),
            vlan_devices = uci.sections('network', 'device'),
            bridges = {};

        // Find bridge VLANs
        for (const section of bridge_vlans) {
            let device = section.device,
                vlan = section.vlan,
                aliases = L.toArray(section.alias),
                ports = L.toArray(section.ports);

            if (!isString(device) || isNaN(vlan) || vlan > 4095) {
                continue;
            }

            let br = bridges[device]
            if (!br) {
                br = { ports: [], vlans: {}, vlan_filtering: true }
            }

            br.vlans[vlan] = [];

            ports.forEach(e => {
                let port = ports[j].replace(/:[ut*]+$/, '');

                if (br.ports.indexOf(port) === -1) {
                    br.ports.push(port);
                }

                br.vlans[vlan].push(port);
            })

            aliases.forEach(e => {
                if (e != vlan) {
                    br.vlans[e] = br.vlans[vlan];
                }
            })
        }

        // Find bridges, VLAN devices
        for (const section of vlan_devices) {
            let type = section.type,
                name = section.name,
                filtering = section.filtering == 1 ? true : false,
                vid = section.vid,
                ifname = section.ifname,
                ports = L.toArray(section.ports);

            if (!isString(name)) {
                continue
            }

            if (type == 'bridge') {
                let br = bridges[name]
                if (!br) {
                    br = { ports: [], vlans: {}, vlan_filtering: true }
                }

                br.vlan_filtering = filtering
                ports.forEach(port => {
                    if (br.ports.indexOf(port) === -1) {
                        br.ports.push(port);
                    }
                })

                mapping[name] = br.ports;
            } else if (type == '8021q' || type == '8021ad') {
                if (!isString(vid) || !isString(ifname)) {
                    continue;
                }

                // Assume that parent is a simple netdev
                mapping[name] = [ifname];
            }
        }
    },

    mapDHCP: function (mapping) {
        const dhcp = uci.sections('dhcp', 'dhcp');

        for (const section of dhcp) {
            let ignore = section.ignore,
                itf = section.interface,
                start = section.start,
                limit = section.limit,
                leasetime = section.leasetime;

            if (ignore == '1' || !itf) {
                continue;
            }

            mapping[itf] = {
                'start': start,
                'limit': limit,
                'leasetime': leasetime
            }
        }
    }
});
