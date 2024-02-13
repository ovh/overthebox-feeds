'use strict';
'require view';
'require uci';
'require fs';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/custom.css')
}));
document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/switch-config.css')
}));

return view.extend({
    load: function () {
        return uci.load('network');
    },

    addPort: function (body, type, port) {
        var el_group,
            el_line,
            id = {},
            port_int = parseInt(port),
            node_before = null;

        if (port_int >= 1 && port_int <= 12) {
            // Ports 1 to 12 should be under group1, paire port values should be on line1 
            port_int % 2 == 0 ? id = { group: 'group1', line: 'line1' } : id = { group: 'group1', line: 'line2' };
        }
        else if (port_int == 13 || port_int == 14) {
            // Ports 13 and 14 should be under group2, paire port values should be on line1
            port_int % 2 == 0 ? id = { group: 'group2', line: 'line1' } : id = { group: 'group2', line: 'line2' };
        } else if (port_int >= 15) {
            // Greater or equal to port 15 should be on group3 line2
            id = { group: 'group3', line: 'line2' };
        }

        el_group = body.getElementById(id.group);

        // Get targeted line
        if (id.line == 'line1') {
            el_line = el_group.firstChild;
        } else {
            el_line = el_group.lastChild;
        }

        for (var i = 0; i < el_line.children.length; i++) {
            // Element should be ordered by port int
            if (parseInt(el_line.children[i].id) > port_int) {
                node_before = el_line.children[i];
                break;
            }
        }

        el_line.insertBefore(E('button', { 'id': port, 'class': 'switch-button ' + type, 'click': this.handleSwitchButton }, [
            E('div', { 'class': 'name' }, port),
            E('div', { 'class': 'type' }, type),
        ]), node_before);
    },

    render: function () {

        var body = E([
            E('div', { 'id': 'switchConfig', 'class': 'switch' }, [
                E('h1', _('Switch Configuration')),
                E('p', _('This section helps you reset the switch ports to a new configuration by selecting the WAN and LAN ports.')),
                E('p', [
                    _('If you need more control, '),
                    E('a', { 'href': '/cgi-bin/luci/admin/network/switch' }, _('go to expert mode')),
                ]),
                E('div', { 'class': 'switches' }, [
                    E('div', { 'class': 'switch' }, E('h2', _('My switch'))),
                    E('div', { 'class': 'portGroup', 'id': 'group1' }, [
                        E('div', { 'class': 'portLine', 'id': 'line1' }),
                        E('div', { 'class': 'portLine', 'id': 'line2' }),
                    ]),
                    E('div', { 'class': 'portGroup', 'id': 'group2' }, [
                        E('div', { 'class': 'portLine', 'id': 'line1' }),
                        E('div', { 'class': 'portLine', 'id': 'line2' }),
                    ]),
                    E('div', { 'class': 'portGroup', 'id': 'group3' }, [
                        E('div', { 'class': 'portLine', 'id': 'line1' }),
                        E('div', { 'class': 'portLine', 'id': 'line2' }),
                    ])
                ]),
                E('div', { 'class': 'cbi-page-actions control-group'}, [
                    E('button', {'class': 'cbi-button cbi-button-apply', 'click': this.handleValidateButton}, _('Save & Apply')),
                    E('button', {'class': 'cbi-button cbi-button-reset', 'click': this.handleResetButton}, _('Reset')),
                ])
            ])
        ]);

        // Retreive and display WANs and LANs from configuration file
        var sw_config = uci.sections('network', 'switch_vlan');
        for (var vlan_i = 0; vlan_i < sw_config.length; vlan_i++) {
            if (sw_config[vlan_i].device == 'otbv2sw') {
                var type = 'wan';
                var _ports = [];
                if (sw_config[vlan_i].vlan == '1') {
                    // Don't display trunk
                    continue;
                } else if (sw_config[vlan_i].vlan == '2') {
                    type = 'lan'
                }
                _ports = sw_config[vlan_i].ports.split(' ');
                for (var port_i = 0; port_i < _ports.length; port_i++) {
                    var vlanType = type;
                    // Don't display tag
                    if (_ports[port_i].search('t') >= 0) {
                        continue;
                    }
                    this.addPort(body, vlanType, _ports[port_i]);
                }
            }
        }
        return body;
    },

    handleValidateButton: function (ev) {
        var groups = ['group1', 'group2', 'group3'],
            el_group,
            el_lines,
            wans = null;

        // Search for wans
        groups.forEach(function (group) {
            el_group = document.getElementById(group);
            for (var child_i = 0; child_i < el_group.children.length; child_i++) {
                el_lines = el_group.children[child_i].childNodes;
                for (var line_i = 0; line_i < el_lines.length; line_i++) {
                    // Get WAN value
                    if (el_lines[line_i].className == "switch-button wan") {
                        var wan_num = el_lines[line_i].firstChild.firstChild.nodeValue;
                        !wans ? wans = wan_num : wans = wans + " " + wan_num;
                    }
                }
            }
        });
        // Update configuration file than restart service
        fs.exec("/usr/bin/swconfig-v2b-reset-todo", [wans]).then(function () {
            // Script execution is OK so refresh page
            location.reload();
        }).catch(function (err) {
            ui.addNotification(null, E('p', err.message));
        });
    },

    handleResetButton: function(ev) {
        var wans = "13 14";
        // Update configuration file than restart service
        fs.exec("/usr/bin/swconfig-v2b-reset-todo", [wans]).then(function () {
            // Script execution is OK so refresh page
            location.reload();
        }).catch(function (err) {
            ui.addNotification(null, E('p', err.message));
        });
    },

    handleSwitchButton: function (ev) {
        var sb = ev.currentTarget
        if (sb.className == 'switch-button lan') {
            sb.className = 'switch-button wan';
            sb.lastChild.firstChild.data = 'wan';
        } else {
            sb.className = 'switch-button lan'
            sb.lastChild.firstChild.data = 'lan';
        }
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
