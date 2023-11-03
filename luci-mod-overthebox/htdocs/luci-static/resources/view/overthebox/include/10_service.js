'use strict';
'require baseclass';
'require fs';
'require uci';
'require ui';
'require tools.overthebox.ui as otbui';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/status.css')
}));

return baseclass.extend({
    title: _('Service'),

    load: function () {
        return Promise.all([
            uci.load('overthebox'),
            fs.exec('/usr/bin/pgrep', ['/usr/sbin/glorytun'], null),
            fs.exec('/usr/bin/pgrep', ['/usr/sbin/glorytun-udp'], null),
            fs.exec('/usr/bin/pgrep', ['ss-redir'], null)
        ]);
    },

    actionRequired: function (action) {
        let btn = E('button', {
            'class': 'cbi-button cbi-button-add',
            'title': action,
            'click': () => {
                if (window.location.href.search('overview') > -1) {
                    window.location.href = window.location.href.replace('overview', 'register')
                } else {
                    window.location.href = window.location.href.concat('admin/overthebox/register')
                }
            }
        }, action);

        switch (action) {
            case 'Register':
                return E('div', { 'class': 'alert-message warning' }, [
                    E('h4', 'Service not registered'),
                    E('p', 'You need to register this device with an active OverTheBox service'),
                    btn
                ]);
                break;
            case 'Activate':
                return E('div', { 'class': 'alert-message warning' }, [
                    E('h4', 'Service not activated'),
                    E('p', 'You need to active your OverTheBox service on this device'),
                    btn
                ]);
                break;
            default:
                return E('div');
        }
    },

    render: function (data) {
        const serviceID = uci.get('overthebox', 'me', 'service'),
            deviceID = uci.get('overthebox', 'me', 'device_id'),
            needsActivation = uci.get('overthebox', 'me', 'needs_activation');


        let box = E('div'),
            steps = [
                { id: 'register', name: 'Register', state: '' },
                { id: 'activate', name: 'Activate', state: '' },
                { id: 'glorytun', name: 'GloryTUN', state: '' },
                { id: 'glorytunUDP', name: 'GloryTUN UDP', state: '' },
                { id: 'shadowSocks', name: 'ShadowSocks', state: '' }
            ];

        // Service need registration
        if (!serviceID) {
            box.appendChild(this.actionRequired('Register'))
            steps[0].state = 'nok'
            box.appendChild(otbui.createStatusBar(steps));
            return box;
        }

        steps[0].state = 'ok'

        if (needsActivation) {
            box.appendChild(this.actionRequired('Activate'))
            steps[1].state = 'nok'
            box.appendChild(otbui.createStatusBar(steps));
            return box;
        }

        steps[1].state = 'ok'

        // Shell return so 0 means ok
        steps[2].state = data[1].code === 0 ? 'ok' : 'nok';
        steps[3].state = data[2].code === 0 ? 'ok' : 'nok';
        steps[4].state = data[3].code === 0 ? 'ok' : 'nok';

        box.appendChild(otbui.createStatusBar(steps));
        box.appendChild(E('div', { 'style': 'display:flex; justify-content:space-between;' }, [
            E('span', [
                E('strong', _('Service ID:') + ' '),
                serviceID
            ]),
            E('span', [
                E('strong', _('Device ID:') + ' '),
                deviceID
            ])
        ]));

        return [box]
    }
});
