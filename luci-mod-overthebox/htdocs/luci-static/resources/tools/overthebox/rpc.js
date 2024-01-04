'use strict';
'require rpc';

return L.Class.extend({
    realtimeStats: function () {
        return rpc.declare({
            object: 'luci',
            method: 'getRealtimeStats',
            params: ['mode', 'device'],
            expect: { result: [] }
        });
    },

    deviceStatus: function () {
        return rpc.declare({
            object: 'network.device',
            method: 'status',
            params: ['name'],
            expect: { '': {} }
        });
    },

    dhcpLeases: function () {
        return rpc.declare({
            object: 'luci-rpc',
            method: 'getDHCPLeases',
            expect: { '': {} }
        });
    },

    callSystemBoard: function () {
        return rpc.declare({
            object: 'system',
            method: 'board'
        });
    },

    callSystemInfo: function () {
        return rpc.declare({
            object: 'system',
            method: 'info'
        });
    }
});
