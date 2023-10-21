'use strict';
'require baseclass';
'require fs';
'require uci';
'require ui';
'require tools.overthebox.ui as otbui';

return baseclass.extend({
        title: _('Service'),

        load: function () {
                return Promise.all([
                        L.resolveDefault(uci.load('overthebox')),
                        L.resolveDefault(fs.exec('/usr/bin/pgrep', ['/usr/sbin/glorytun'], null)),
                        L.resolveDefault(fs.exec('/usr/bin/pgrep', ['/usr/sbin/glorytun-udp'], null)),
                        L.resolveDefault(fs.exec('/usr/bin/pgrep', ['ss-redir'], null))
                ]);
        },

        render: function (data) {
                const otb = uci.sections('overthebox', 'config');

                let box = E('div'),
                    serviceID = Array.isArray(otb) ? otb[0].service : '',
                    deviceID = Array.isArray(otb) ? otb[0].device_id : ''

                // Format System data table
                var fields = [
                        _('Service ID'), serviceID,
                        _('Device ID'), deviceID,
                        _('GloryTun'), data[1].code === 0 ? '\u2705 '+_('Running'): '\u274C '+_('Stopped'),
                        _('GloryTun UDP'), data[2].code === 0 ? '\u2705 '+_('Running'): '\u274C '+_('Stopped'),
                        _('ShadowSocks'), data[3].code === 0 ? '\u2705 '+_('Running'): '\u274C '+_('Stopped')
                ];

                let table = otbui.createTabularElem(fields);

                // Service need activation
                if (!serviceID) {
                    let btn = E('button', {'class': 'cbi-button cbi-button-add', 'title': 'Register'}, 'Register');

                    btn.onclick = () => {
                        if (window.location.href.search('overview') > -1) {
                            window.location.href=window.location.href.replace('overview', 'register')
                        } else {
                            window.location.href=window.location.href.concat('admin/overthebox/register')
                        }
                    }

                    box.appendChild(E('div', {'class': 'alert-message warning'}, [
                        E('h4', 'Service not registered'),
                        E('p', 'You need to register this device with an active OverTheBox service'),
                        btn
                    ]))
                }

                box.appendChild(table);
                return [ box ]
        }
});
