'use strict';
'require baseclass';
'require network';
'require fs';
'require firewall';
'require uci';
'require tools.overthebox.ui as otbui';
'require tools.overthebox.ipcalc as ipcalc';
'require tools.overthebox.mapping as mapping';

function getASNName(dir) {
    return fs.read_direct(dir + '/asn', 'json').then((r) => r.as_description || 'Unknown');
}

function getWANIP(dir) {
    return fs.trimmed(dir + '/public_ip').then((r) => r || '0.0.0.0');
}

function getLatency(dir) {
    return fs.trimmed(dir + '/latency').then((r) => r || '-');
}

function getOTBData(name) {
    let dir = '/tmp/otb-data/' + name;

    return Promise.all([
        getWANIP(dir),
        getASNName(dir),
        getLatency(dir),
    ])
}

return baseclass.extend({
    title: _('Networks'),

    otbData: new Map(),
    VLAN: {},
    DHCP: {},

    load: function () {
        return Promise.all([
            network.getNetworks(),
            firewall.getZones(),
            uci.load('network'),
            L.resolveDefault(uci.load('dhcp'))
        ])
    },

    renderDevice: function (dev) {
        let name = 'Port',
            speed = null,
            duplex = null,
            trafficTable = '';

        if (dev) {
            name = dev.getName();
            speed = dev.getSpeed();
            duplex = dev.getDuplex();

            let trafficFields = [
                _('Mac'), dev.getMAC(),
                _('Up'), '%1024.1mB'.format(dev.getTXBytes()),
                _('Down'), '%1024.1mB'.format(dev.getRXBytes())
            ];

            trafficTable = otbui.createTabularElem(trafficFields);
        }

        let box;
        if (this.VLAN[name]) {
            box = otbui.createIfaceElem([name], [
                E('img', { 'src': L.resource('icons/%s.png').format(dev.getType()) }),
                E('br'),
                dev.getType(),
                trafficTable
            ]);

            let content = E('div', { 'style': 'display:flex;flex-wrap:wrap;margin-bottom:1em' });
            this.VLAN[name].forEach(e => content.appendChild(this.renderDevice(network.instantiateDevice(e))));
            box.appendChild(content)
        } else {
            box = otbui.createIfaceElem([name], [
                E('img', { 'src': L.resource('icons/port_%s.png').format((speed && duplex) ? 'up' : 'down') }),
                E('br'),
                otbui.formatEthSpeed(speed, duplex),
                trafficTable
            ]);
        }

        return box;
    },

    renderDHCP: function (net) {
        const name = net.getName(),
            ipv4Addrs = net.getIPAddrs();

        let dhcp = this.DHCP[name];

        // Weird case this shouldn't happen
        if (!dhcp) {
            return otbui.createIfaceElem(['DHCP'], ['No DHCP Server found']);
        }

        let range = ipcalc.getRange(ipv4Addrs[0], dhcp.start, dhcp.limit);

        let fields = [
            _('Network'), range.network,
            _('Netmask'), range.netmask,
            _('Server'), range.ip,
            _('Start'), range.start,
            _('End'), range.end,
            _('Broadcast'), range.broadcast,
            _('Lease Time'), dhcp.leasetime
        ];

        let table = otbui.createTabularElem(fields);

        return otbui.createIfaceElem(['DHCP'], [table]);
    },

    renderNetwork: function (type, net) {
        const name = net.getName(),
            gateway = net.getGatewayAddr(),
            expires = net.getExpiry(),
            uptime = net.getUptime(),
            ipv4Addrs = net.getIPAddrs(),
            color = net.isUp() ? 'green' : 'red';

        let ipFields = [
            _('Protocol'), net.getI18n() || E('em', _('Not connected')),
            _('Address'), ipv4Addrs[0],
            _('Expires'), (expires != null && expires > -1) ? '%t'.format(expires) : null,
            _('Connected'), (uptime > 0) ? '%t'.format(uptime) : null,
        ];

        // Generate details summary
        let summary = name;
        if (gateway) {
            summary += ' (' + gateway + ')';

            ipFields.push(
                _('Gateway'), gateway,
            );
        }

        if (type === 'wan') {
            // Get OTB data
            getOTBData(name).then(
                (res) => {
                    this.otbData.set(name + 'WANIP', res[0]);
                    this.otbData.set(name + 'WHOIS', res[1]);
                    this.otbData.set(name + 'Latency', res[2] + ' ms');
                });

            summary += ' ' + this.otbData.get(name + 'Latency');
            ipFields.push(
                _('WAN IP'), this.otbData.get(name + 'WANIP'),
                _('WHOIS'), this.otbData.get(name + 'WHOIS'),
                _('Latency'), this.otbData.get(name + 'Latency'),
            );
        }

        // Generate details body
        let body = E('div', { 'style': 'display:flex;margin:.35em;min-width:225px;max-width:max-content' });

        body.appendChild(this.renderDevice(net.getL3Device()));

        // Render Connection data
        body.appendChild(otbui.createIfaceElem([_('Connection')], [otbui.createTabularElem(ipFields)]));

        // Render DHCP data
        if (this.DHCP[name]) {
            body.appendChild(this.renderDHCP(net));
        }

        return otbui.createDetailsElem(name, summary, body, color);
    },

    renderZones: function (zones, networks) {
        let netmap = {};

        mapping.mapVLAN(this.VLAN);
        mapping.mapDHCP(this.DHCP);

        networks.forEach(net => netmap[net.getName()] = net);

        let wrap = E('div');
        for (const zone of zones) {
            let zonename = zone.getName(),
                networknames = zone.getNetworks();

            if (!networknames.length) {
                continue
            }

            let box = E('div', [
                E('h2', zonename.toUpperCase())
            ])

            for (const net of networknames) {
                if (!netmap[net]) {
                    continue;
                }

                box.appendChild(this.renderNetwork(
                    zonename === 'lan' ? 'lan' : 'wan',
                    netmap[net]

                ));
            }

            wrap.appendChild(box);
        }

        return wrap
    },

    render: function (data) {
        let net = data[0];
        let zones = data[1];
        return this.renderZones(zones, net);
    }
});
