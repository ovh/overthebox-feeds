'use strict';
'require baseclass';
'require fs';
'require rpc';
'require uci';
'require network';
'require firewall';
'require tools.overthebox.ui as otbui';
'require tools.overthebox.rpc as otbrpc';
'require tools.overthebox.ipcalc as ipcalc';
'require tools.overthebox.mapping as mapping';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/networkmap.css')
}));

function getASNName(dir) {
    return fs.read_direct(dir + '/asn', 'json').then((r) => r.as_description || _('Unknown'));
}

function getWANIP(dir) {
    return fs.trimmed(dir + '/public_ip').then((r) => r || '0.0.0.0');
}

function getLatency(dir) {
    return fs.trimmed(dir + '/latency').then((r) => r || '-');
}

function getConnectivity(dir) {
    return fs.trimmed(dir + '/connectivity').then((r) => r || _('ERROR'));
}

function getOTBData(name) {
    let dir = '/tmp/otb-data/' + name;

    return Promise.all([
        getWANIP(dir),
        getASNName(dir),
        getLatency(dir),
        getConnectivity(dir),
    ])
}

return baseclass.extend({
    title: _('Network'),

    otbData: new Map(),
    DHCP: {},

    load: function () {
        const rpcBoard = otbrpc.callSystemBoard(),
            rpcInfo = otbrpc.callSystemInfo();

        return Promise.all([
            rpcBoard(),
            rpcInfo(),
            fs.lines('/etc/otb-version'),
            network.getNetworks(),
            firewall.getZones(),
            uci.load('network'),
            uci.load('dhcp')
        ]);
    },

    renderOTB: function (board, system, version) {
        const time = system.localtime ? otbui.formatLocalTime(system.localtime) : null,
            uptime = system.uptime ? '%t'.format(system.uptime) : null,
            load = otbui.formatLoad(system.load),
            model = otbui.formatModel(board.model);


        return E('div', { 'class': 'network-otb' }, [
            E('div', { 'class': 'network-infos' }, [
                E('div', { 'class': 'network-title' }, [board.hostname]),
                E('div', { 'class': 'network-icon' }, [
                    // E('img', {'src': '/luci-static/resources/ovh/images/overthebox.png'})
                    E('img', { 'src': '/luci-static/resources/ovh/images/otb.svg' })
                ]),
                E('div', { 'class': 'network-content' }, [
                    E('span', { 'class': 'nowrap' }, [_('Model') + " : " + model]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Firmware') + " : " + version[0]]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Kernel') + " : " + board.kernel]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Time') + " : " + time]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Uptime') + " : " + uptime]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Load') + " : " + load]),
                ])
            ])
        ]);
    },

    renderNet: function (zone, net) {
        const name = net.getName(),
            device = net.getL3Device(),
            itf = device ? device.getName() : _('None'),
            gateway = net.getGatewayAddr(),
            expiry = net.getExpiry(),
            uptime = net.getUptime(),
            ipv4Addrs = net.getIPAddrs(),
            address = ipv4Addrs[0],
            protocol = net.getI18n(),
            connected = (uptime > 0) ? '%t'.format(uptime) : null,
            expires = (expiry != null && expiry > -1) ? '%t'.format(expiry) : null;

        let up = net.isUp() ? 'Online' : 'Offline',
            // translatable var
            up_t = net.isUp() ? _('Online') : _('Offline'),
            summary = uci.get('network', name, 'label'),
            content = [
                E('span', { 'class': 'nowrap' }, [_('Status') + " : " + up_t]),
                E('br'),
                E('span', { 'class': 'nowrap' }, [_('Interface') + " : " + itf]),
            ],
            otbdata = false,
            details = [],
            img = '/luci-static/resources/ovh/images/disconnected.svg';

        if (!summary) {
            summary = name;
        }

        if (gateway) {
            summary += ' (' + gateway + ')';
        }

        if (net.isUp()) {
            details.push(
                E('span', { 'class': 'nowrap' }, [_('Address') + " : " + address]),
                E('br'),
                E('span', { 'class': 'nowrap' }, [_('Uptime') + " : " + connected]),
                E('br'),
                E('span', { 'class': 'nowrap' }, [_('Protocol') + " : " + protocol]),
            );

            // Set expires if we it exist, if address comes from a DHCP
            if (expires) {
                details.push(
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Expires') + " : " + expires]),
                );
            }

            // Render DHCP data
            if (this.DHCP[name]) {
                const range = ipcalc.getRange(address, this.DHCP[name].start, this.DHCP[name].limit);
                if (!gateway) {
                    summary += ' (' + range.ip + ')';
                }

                details.push(
                    E('br'),
                    E('span', [_('DHCP') + " :"]),
                    E('ul', [
                        E('li', { 'class': 'nowrap' }, [_('Begin') + " : " + range.start]),
                        E('li', { 'class': 'nowrap' }, [_('End') + " : " + range.end]),
                        E('li', { 'class': 'nowrap' }, [_('Netmask') + " : " + range.netmask]),
                        E('li', { 'class': 'nowrap' }, [_('Lease Time') + " : " + this.DHCP[name].leasetime])
                    ]),
                );
            }

            // Retrieve otb data for TUN and WAN zone
            if (zone != 'lan') {
                otbdata = true;

                getOTBData(name)
                    .then(
                        res => {
                            this.otbData.set(name + 'WANIP', res[0]);
                            this.otbData.set(name + 'WHOIS', res[1]);
                            this.otbData.set(name + 'Latency', res[2] + ' ms');
                            this.otbData.set(name + 'Status', res[3])
                        }
                    )
                    .catch(
                        err => {
                            console.log(_('Fail to get otb data'));
                            otbdata = false;
                        }
                    );
            }

            img = '/luci-static/resources/ovh/images/' + zone + '.svg'
        }

        if (otbdata) {
            // Interface is not truely connected
            // Could happens with OTB v2B and our VLAN usage
            if (this.otbData.get(name + 'Status') != 'OK') {
                up = 'Offline';
                up_t = _('Offline');

                content = [
                    E('span', { 'class': 'nowrap' }, [_('Status') + " : " + up_t]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Interface') + " : " + itf]),
                ];
                details = [];
                img = '/luci-static/resources/ovh/images/disconnected.svg';
            } else {
                content.push(
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('WAN IP') + " : " + this.otbData.get(name + 'WANIP')]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('WHOIS') + " : " + this.otbData.get(name + 'WHOIS')]),
                    E('br'),
                    E('span', { 'class': 'nowrap' }, [_('Latency') + " : " + this.otbData.get(name + 'Latency')]),
                )
            }
        }

        const infos = [
            E('div', { 'class': 'network-title' }, [summary]),
            E('div', { 'class': 'network-icon' }, [
                E('img', { 'src': img })
            ]),
            E('div', { 'class': 'network-content' }, content),
        ];

        if (details.length !== 0) {
            infos.push(
                otbui.createNetDetailsElem(name, details)
            )
        }

        return E('div', { 'class': 'network-node-' + up.toLowerCase() }, [
            E('div', { 'class': 'network-infos' }, infos)
        ]);
    },

    render: function (data) {
        const nets = data[3],
            zones = data[4];

        const zoneAreas = [
            this.renderOTB(data[0], data[1], data[2])
        ];

        // Index networks
        let netIndex = {};
        nets.forEach(net => netIndex[net.getName()] = net);

        // Index DHCP
        mapping.mapDHCP(this.DHCP);

        // Iterate over firewall zone
        for (const z of zones) {
            const zone = {
                name: z.getName().toLowerCase(),
                nets: z.getNetworks(),
            },
                area = E('div', { 'class': 'network-zone-' + zone.name }, [
                    E('div', { 'class': 'network-zone-title' }, [zone.name])
                ]),
                nodes = E('div', { 'class': 'network-zone-nodes-' + zone.name });

            // We are just checking lan, wan and tun zone
            if (!['lan', 'wan', 'tun'].includes(zone.name)) {
                continue;
            }

            if (!zone.nets.length) {
                nodes.appendChild(E('span', [E('em', _('No network found...'))]))
            } else {
                for (const n of zone.nets) {
                    if (!netIndex[n]) {
                        continue;
                    }

                    nodes.appendChild(this.renderNet(zone.name, netIndex[n]));
                }
            }

            area.appendChild(nodes)
            zoneAreas.push(area)
        }

        return E('div', { 'class': 'network-map' }, zoneAreas);
    }
});
