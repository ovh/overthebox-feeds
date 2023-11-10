'use strict';
'require baseclass';
'require fs';
'require rpc';
'require network';
'require tools.overthebox.ui as otbui';

var callSystemBoard = rpc.declare({
        object: 'system',
        method: 'board'
});

var callSystemInfo = rpc.declare({
        object: 'system',
        method: 'info'
});

return baseclass.extend({
        title: _('System'),

        load: function () {
                return Promise.all([
                        L.resolveDefault(callSystemBoard(), {}),
                        L.resolveDefault(callSystemInfo(), {}),
                        fs.lines('/etc/otb-version')
                ]);
        },

        render: function (data) {
                let board = data[0];
                let system = data[1];
                let version = data[2];

                // Format local time
                let time = null;
                if (system.localtime) {
                        time = otbui.formatLocalTime(system.localtime);
                }

                // Format load
                let load = otbui.formatLoad(system.load);

                // Format System data table
                var fields = [
                        _('Hostname'), board.hostname,
                        _('Model'), board.model,
                        _('Firmware Version'), version[0],
                        _('Kernel Version'), board.kernel,
                        _('Local Time'), time,
                        _('Uptime'), system.uptime ? '%t'.format(system.uptime) : null,
                        _('Load Average'), load
                ];

                let table = otbui.createTabularElem(fields);

                // Create collapsible
                return otbui.createDetailsElem('system', board.hostname, table, 'blue');
        }
});
