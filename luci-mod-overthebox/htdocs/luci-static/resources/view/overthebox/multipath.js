'use strict';
'require view';
'require dom';
'require poll';
'require fs';
'require ui';
'require uci';
'require form';
'require network';
'require firewall';
'require tools.network as nettools';

let isReadonlyView = !L.hasViewPermission() || null;

function count_changes(section_id) {
    let changes = ui.changes.changes, n = 0;

    if (!L.isObject(changes)) {
        return n;
    }

    if (Array.isArray(changes.network)) {
        for (let i = 0; i < changes.network.length; i++) {
            n += (changes.network[i][1] == section_id);
        }
    }

    if (Array.isArray(changes.sqm)) {
        for (let i = 0; i < changes.sqm.length; i++) {
            n += (changes.sqm[i][1] == section_id);
        }
    }

    return n;
}

function render_iface(dev, alias) {
    let type = dev ? dev.getType() : 'ethernet',
        up = dev ? dev.isUp() : false;

    return E('span', { class: 'cbi-tooltip-container' }, [
        E('img', {
            'class': 'middle', 'src': L.resource('icons/%s%s.png').format(
                alias ? 'alias' : type,
                up ? '' : '_disabled')
        }),
        E('span', { 'class': 'cbi-tooltip ifacebadge large' }, [
            E('img', {
                'src': L.resource('icons/%s%s.png').format(
                    type, up ? '' : '_disabled')
            }),
            L.itemlist(E('span', { 'class': 'left' }), [
                _('Type'), dev ? dev.getTypeI18n() : null,
                _('Device'), dev ? dev.getName() : _('Not present'),
                _('Connected'), up ? _('yes') : _('no'),
                _('MAC'), dev ? dev.getMAC() : null,
                _('RX'), dev ? '%.2mB (%d %s)'.format(dev.getRXBytes(), dev.getRXPackets(), _('Pkts.')) : null,
                _('TX'), dev ? '%.2mB (%d %s)'.format(dev.getTXBytes(), dev.getTXPackets(), _('Pkts.')) : null
            ])
        ])
    ]);
}

function render_status(node, ifc, with_device) {
    let desc = null, c = [];

    if (ifc.isDynamic()) {
        desc = _('Virtual dynamic interface');
    } else if (ifc.isAlias()) {
        desc = _('Alias Interface');

    } else if (!uci.get('network', ifc.getName())) {
        return L.itemlist(node, [
            null, E('em', _('Interface is marked for deletion'))
        ]);
    }

    desc = desc ? '%s (%s)'.format(desc, ifc.getI18n()) : ifc.getI18n();

    const changecount = with_device ? 0 : count_changes(ifc.getName());
    const maindev = ifc.getL3Device() || ifc.getDevice();
    const macaddr = maindev ? maindev.getMAC() : null;
    const cond00 = !changecount && !ifc.isDynamic() && !ifc.isAlias();
    const cond01 = cond00 && macaddr;
    const cond02 = cond00 && maindev;

    function addEntries(label, array) {
        return Array.isArray(array) ? array.flatMap((item) => [label, item]) : [label, null];
    }

    return L.itemlist(node, [
        _('Uptime'), (!changecount && ifc.isUp()) ? '%t'.format(ifc.getUptime()) : null,
        ...addEntries(_('IPv4'), changecount ? [] : ifc.getIPAddrs()),
        ...addEntries(_('IPv6'), changecount ? [] : ifc.getIP6Addrs()),
        ...addEntries(_('IPv6-PD'), changecount ? null : ifc.getIP6Prefixes?.()),
        _('Physical layer'), ifc.get('physicallayer') ? ifc.get('physicallayer').toUpperCase() : null,
        _('MPTCP'), ifc.get('multipath'),
    ]);
}

function render_ifacebox_status(node, ifc) {
    let dev = ifc.getL3Device() || ifc.getDevice(),
        subdevs = dev ? dev.getPorts() : null,
        c = [render_iface(dev, ifc.isAlias())];

    if (subdevs && subdevs.length) {
        let sifs = [' ('];

        for (let j = 0; j < subdevs.length; j++)
            sifs.push(render_iface(subdevs[j]));

        sifs.push(')');

        c.push(E('span', {}, sifs));
    }

    c.push(E('br'));
    c.push(E('small', {}, ifc.isAlias() ? _('Alias of "%s"').format(ifc.isAlias())
        : (dev ? dev.getName() : E('em', _('Not present')))));

    dom.content(node, c);

    return L.bind(function (ifc) {
        this.style.backgroundColor = ifc.isUp() ? zone.getColorStyle('lan') : zone.getColorStyle('wan');
        this.title = zone ? _('Part of zone %q').format(zone.getName()) : _('No zone assigned');
    }, node.previousElementSibling);
}

function iface_autoqos(up, id, ev) {
    let row = document.querySelector('.cbi-section-table-row[data-sid="%s"]'.format(id)),
        dsc = row.querySelector('[data-name="_ifacestat"] > div'),
        btns = row.querySelectorAll('.cbi-section-actions .autoqos');

    btns[0].blur();
    btns[0].classList.add('spinning');

    btns[0].disabled = true;

    dsc.setAttribute('autoqos', '');
    dom.content(dsc, E('em', _('AutoQoS is running...')));
}

return view.extend({
    poll_status: function (map, networks) {
        let resolveZone = null;

        for (let i = 0; i < networks.length; i++) {
            let ifc = networks[i],
                row = map.querySelector('.cbi-section-table-row[data-sid="%s"]'.format(ifc.getName()));

            if (row == null) {
                continue;
            }

            let dsc = row.querySelector('[data-name="_ifacestat"] > div'),
                box = row.querySelector('[data-name="_ifacebox"] .ifacebox-body'),
                btn2 = row.querySelector('.cbi-section-actions .autoqos'),
                stat = document.querySelector('[id="%s-ifc-status"]'.format(ifc.getName())),
                resolveZone = render_ifacebox_status(box, ifc),
                disabled = ifc ? !ifc.isUp() : true,
                dynamic = ifc ? ifc.isDynamic() : false;

            if (dsc.hasAttribute('autoqos')) {
                dom.content(dsc, E('em', _('AutoQoS is running...')));
            } else if (ifc.getProtocol() || uci.get('network', ifc.getName()) == null) {
                render_status(dsc, ifc, false);
            } else if (!ifc.getProtocol()) {
                let e = map.querySelector('[id="cbi-network-%s"] .cbi-button-edit'.format(ifc.getName()));
                if (e) {
                    e.disabled = true;
                }

                let link = L.url('admin/system/package-manager') + '?query=luci-proto';
                dom.content(dsc, [
                    E('em', _('Unsupported protocol type.')), E('br'),
                    E('a', { href: link }, _('Install protocol extensions...'))
                ]);
            } else {
                dom.content(dsc, E('em', _('Interface not present or not connected yet.')));
            }

            if (stat) {
                let dev = ifc.getDevice();
                dom.content(stat, [
                    E('img', {
                        'src': L.resource('icons/%s%s.png').format(dev ? dev.getType() : 'ethernet', (dev && dev.isUp()) ? '' : '_disabled'),
                        'title': dev ? dev.getTypeI18n() : _('Not present')
                    }),
                    render_status(E('span'), ifc, true)
                ]);
            }

            btn2.disabled = isReadonlyView || btn2.classList.contains('spinning') || dynamic || disabled;
        }

        document.querySelectorAll('.port-status-device[data-device]').forEach(function (node) {
            nettools.updateDevBadge(node, network.instantiateDevice(node.getAttribute('data-device')));
        });

        document.querySelectorAll('.port-status-link[data-device]').forEach(function (node) {
            nettools.updatePortStatus(node, network.instantiateDevice(node.getAttribute('data-device')));
        });

        return Promise.all([resolveZone, network.flushCache()]);
    },

    load: function () {
        return Promise.all([
            network.getDevices(),
            uci.changes(),
            uci.load('network'),
            uci.load('sqm'),
        ]);
    },

    deviceWithIfnameSections: function () {
        return uci.sections('network', 'device').filter(function (ns) {
            return ns.type == 'bridge' && !ns.ports && ns.ifname;
        });
    },

    render: function (data) {
        let netDevs = data[0],
            m, s, o;

        m = new form.Map('network');
        m.chain('sqm');

        s = m.section(form.GridSection, 'interface', _('Multipath'), _('Setup Multipath and QoS'));
        s.anonymous = true;

        s.load = function () {
            return Promise.all([
                network.getNetworks(),
                firewall.getZones(),
                uci.load('system'),
            ]).then(L.bind(function (data) {
                this.networks = data[0];
                this.zones = data[1];
            }, this));
        };

        s.cfgsections = function () {
            return this.networks.map(function (n) {
                if (n.getType() === '') {
                    return n.getName();
                }
            }).filter(function (n) {
                if (!['lan', 'loopback'].includes(n)) {
                    return n;
                }
            });
        };

        s.modaltitle = function (section_id) {
            return _('Interfaces') + ' » ' + section_id;
        };

        s.renderRowActions = function (section_id) {
            let tdEl = this.super('renderRowActions', [section_id, _('Edit')]),
                net = this.networks.filter(function (n) { return n.getName() == section_id })[0],
                disabled = net ? !net.isUp() : true;

            dom.content(tdEl.lastChild, [
                E('button', {
                    'class': 'cbi-button cbi-button-neutral autoqos',
                    'click': iface_autoqos.bind(this, false, section_id),
                    'title': _('Auto configure QoS'),
                    'disabled': (disabled) ? 'disabled' : null
                }, _('autoQoS')),
                tdEl.lastChild.firstChild,
            ]);

            if (net && !uci.get('network', net.getName())) {
                tdEl.lastChild.childNodes[0].disabled = true;
                tdEl.lastChild.childNodes[1].disabled = true;
            }

            return tdEl;
        };

        // Multipath modal
        s.tab('multipath', _('Multipath Settings'), _('Configure Multipath'));

        o = s.taboption('multipath', form.ListValue, 'physicallayer', _('Physical layer'), _('Set link technology to adapt glorytun'));
        o.value('ethernet', _('Ethernet'));
        o.value('adsl', _('ADSL'));
        o.value('vdsl', _('VDSL'));
        o.value('4g', _('4G'));
        o.value('5g', _('5G'));
        o.value('satellite', _('Satellite'));
        o.modalonly = true;

        o = s.taboption('multipath', form.Value, 'label', _('Label'), _('Label this interface'));
        o.placeholder = _('Interface label');
        o.rmempty = true;
        o.modalonly = true;

        o = s.taboption('multipath', form.ListValue, 'multipath', _('Multipath TCP'), _('Configure multipath mode'));
        o.value('on', _('enabled'));
        o.value('off', _('disabled'));
        o.value('master', _('master'));
        o.value('backup', _('backup'));
        o.value('handover', _('handover'));
        o.default = 'off';
        o.modalonly = true;

        // QoS modal
        s.tab('qos', _('QoS Settings'), _('Configure SQM'));

        o = s.taboption('qos', form.Flag, 'enabled', _("Enabled"), _("Not recommended for interface over 300Mbps"));
        o.modalonly = true
        o.uciconfig = 'sqm'
        o.ucioption = 'enabled'
        o.rmempty = false;
        o.cfgvalue = function (section_id) {
            return uci.get('sqm', section_id, 'enabled');
        }
        o.write = function (section_id, value) {
            if (!uci.get('sqm', section_id)) {
                uci.add('sqm', 'queue', section_id)
            }
            return uci.set('sqm', section_id, 'enabled', value);
        }

        o = s.taboption('qos', form.Value, 'download', _("Download"), _("Download (kbit/s)"));
        o.modalonly = true
        o.uciconfig = 'sqm'
        o.ucioption = 'download'
        o.datatype = "and(uinteger,min(0))";
        o.rmempty = false;
        o.depends('enabled', '1');
        o.cfgvalue = function (section_id) {
            return uci.get('sqm', section_id, 'download');
        }
        o.write = function (section_id, value) {
            return uci.set('sqm', section_id, 'download', value);
        }

        o = s.taboption('qos', form.Value, 'upload', _("Upload"), _("Upload (kbit/s)"));
        o.datatype = "and(uinteger,min(0))";
        o.modalonly = true;
        o.uciconfig = 'sqm';
        o.ucioption = 'upload';
        o.rmempty = false;
        o.depends('enabled', '1');
        o.cfgvalue = function (section_id) {
            return uci.get('sqm', section_id, 'upload');
        }
        o.write = function (section_id, value) {
            return uci.set('sqm', section_id, 'upload', value);
        }

        o = s.taboption('qos', form.ListValue, 'linklayer', _("Link layer"), _("Which link layer technology to account for"));
        o.modalonly = true;
        o.uciconfig = 'sqm';
        o.ucioption = 'linklayer';
        o.value("none", "none (" + _("default") + ")");
        o.value("ethernet", "PTM: VDSL2");
        o.value("atm", "ATM: ADSL2+");
        o.depends('enabled', '1');
        o.default = "none";
        o.rmempty = false;
        o.cfgvalue = function (section_id) {
            return uci.get('sqm', section_id, 'linklayer');
        }
        o.write = function (section_id, value) {
            return uci.set('sqm', section_id, 'linklayer', value);
        }

        o = s.taboption('qos', form.Value, 'overhead', _("Overhead"), _("Per Packet Overhead (bytes)"));
        o.modalonly = true;
        o.uciconfig = 'sqm';
        o.ucioption = 'overhead';
        o.datatype = "and(integer,min(-1500))";
        o.default = 0;
        o.depends('linklayer', "ethernet");
        o.depends('linklayer', "atm");
        o.rmempty = false;
        o.cfgvalue = function (section_id) {
            return uci.get('sqm', section_id, 'overhead');
        }
        o.write = function (section_id, value) {
            return uci.set('sqm', section_id, 'overhead', value);
        }

        s.handleModalCancel = function (/* ... */) {
            let type = uci.get('network', this.activeSection || this.addedSection, 'type'),
                device = (type == 'bridge') ? 'br-%s'.format(this.activeSection || this.addedSection) : null;

            uci.sections('network', 'bridge-vlan', function (bvs) {
                if (device != null && bvs.device == device) {
                    uci.remove('network', bvs['.name']);
                }
            });

            return form.GridSection.prototype.handleModalCancel.apply(this, arguments);
        };

        o = s.option(form.DummyValue, '_ifacebox');
        o.modalonly = false;
        o.textvalue = function (section_id) {
            let net = this.section.networks.filter(function (n) { return n.getName() == section_id })[0],
                zone = net ? this.section.zones.filter(function (z) { return !!z.getNetworks().filter(function (n) { return n == section_id })[0] })[0] : null;

            if (!net) {
                return;
            }

            let name = uci.get('network', section_id, 'label');
            if (!name) {
                name = net.getName().toUpperCase();
            }

            let hex = net.isUp() ? '#90f090' : '#f09090';
            let node = E('div', { 'class': 'ifacebox' }, [
                E('div', {
                    'class': 'ifacebox-head',
                    'style': '--zone-color-rgb:%d, %d, %d; background-color:rgb(var(--zone-color-rgb))'.format(
                        parseInt(hex.substring(1, 3), 16),
                        parseInt(hex.substring(3, 5), 16),
                        parseInt(hex.substring(5, 7), 16)
                    ),
                    'title': zone ? _('Part of zone %q').format(zone.getName()) : _('No zone assigned')
                }, E('strong', name)),
                E('div', {
                    'class': 'ifacebox-body',
                    'id': '%s-ifc-devices'.format(section_id),
                    'data-network': section_id
                }, [

                    E('img', {
                        'src': L.resource('icons/ethernet_disabled.png'),
                        'style': 'width:16px; height:16px'
                    }),
                    E('br'), E('small', '?')
                ])
            ]);

            render_ifacebox_status(node.childNodes[1], net);

            return node;
        };

        o = s.option(form.DummyValue, '_ifacestat', _('Multipath'));
        o.modalonly = false;
        o.textvalue = function (section_id) {
            const net = this.section.networks.filter(function (n) { return n.getName() == section_id })[0];

            if (!net) {
                return;
            }

            const node = E('div', { 'id': '%s-ifc-description'.format(section_id) });

            render_status(node, net, false);

            return node;
        };

        o = s.option(form.DummyValue, '_ifacegt', _('Glorytun'));
        o.modalonly = false;
        o.textvalue = function (section_id) {
            const net = this.section.networks.filter(function (n) { return n.getName() == section_id })[0];

            if (!net) {
                return;
            }

            const node = E('div', { 'id': '%s-ifc-glorytun'.format(section_id) });
            let itf_linklayer = uci.get('network', section_id, 'physicallayer');
            itf_linklayer ??= 'ethernet';

            let gt_mode = 'auto', gt_rx = '1000Mbps', gt_tx = '1000Mbps';
            switch (itf_linklayer.toLowerCase()) {
                case '4g':
                    gt_mode = 'fixed';
                    gt_rx = '300Mbps';
                    gt_tx = '100Mbps';
                    break;
                case '5g':
                    gt_mode = 'fixed';
                    gt_rx = '600Mbps';
                    gt_tx = '200Mbps';
                    break;
                case 'satellite':
                    gt_mode = 'fixed';
                    gt_rx = '100Mbps';
                    gt_tx = '25Mbps';
                    break;
                case 'adsl':
                    gt_rx = '25Mbps';
                    gt_tx = '4Mbps';
                    break;
                case 'vdsl':
                    gt_rx = '100Mbps';
                    gt_tx = '10Mbps';
                    break;
            }

            return L.itemlist(node, [
                _('Rate mode'), gt_mode,
                _('RX'), gt_rx,
                _('TX'), gt_tx,
            ]);

            return node;
        };

        o = s.option(form.DummyValue, '_ifacesqm', _('SQM'));
        o.modalonly = false;
        o.textvalue = function (section_id) {
            const net = this.section.networks.filter(function (n) { return n.getName() == section_id })[0];
            if (!net) {
                return;
            }

            const node = E('div', { 'id': '%s-ifc-sqm'.format(section_id) });

            const sqm_enabled = uci.get('sqm', section_id)
            if (!sqm_enabled) {
                node.append(E('em', [_('SQM disabled')]))
                return node
            }

            const sqm_download = uci.get('sqm', section_id, 'download'),
                sqm_upload = uci.get('sqm', section_id, 'upload'),
                sqm_linklayer = uci.get('sqm', section_id, 'linklayer'),
                sqm_overhead = uci.get('sqm', section_id, 'overhead');

            return L.itemlist(node, [
                _('Download'), sqm_download ? sqm_download : null,
                _('Upload'), sqm_upload ? sqm_upload : null,
                _('Linklayer'), sqm_linklayer ? sqm_linklayer : null,
                _('Overhead'), sqm_overhead ? sqm_overhead : null,
            ]);

            return node;
        };

        return m.render().then(L.bind(function (m, nodes) {
            poll.add(L.bind(function () {
                let section_ids = m.children[0].cfgsections(),
                    tasks = [];

                for (let i = 0; i < section_ids.length; i++) {
                    let row = nodes.querySelector('.cbi-section-table-row[data-sid="%s"]'.format(section_ids[i])),
                        dsc = row.querySelector('[data-name="_ifacestat"] > div'),
                        btn2 = row.querySelector('.cbi-section-actions .autoqos');

                    if (dsc.getAttribute('autoqos') == '') {
                        dsc.setAttribute('autoqos', '1');
                        tasks.push(fs.exec_direct('/bin/otb-auto-sqm', [section_ids[i]]).catch(function (e) {
                            console.log(e)
                            ui.addNotification(null, E('p', e.message));
                        }));
                    }
                    else if (dsc.getAttribute('autoqos') == '1') {
                        dsc.removeAttribute('autoqos');
                        btn2.classList.remove('spinning');
                        btn2.disabled = false;
                        poll.stop();
                        window.location.reload();
                    }
                }

                return Promise.all(tasks)
                    .then(L.bind(network.getNetworks, network))
                    .then(L.bind(this.poll_status, this, nodes));
            }, this), 5);

            return nodes;
        }, this, m));
    }
});
