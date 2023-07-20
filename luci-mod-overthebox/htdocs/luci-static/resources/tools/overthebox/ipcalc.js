'use strict';

// This a port of awk tools /bin/ipcalc.sh in js
// >>>0 is necessary to force an unsigned int

function ip2int(ipv4) {
    const ip = ipv4.split(".").map(Number)
    let ret = 0;

    for (let x = 0; x < ip.length; x++) {
        ret = ((ret << 8 >>> 0) | ip[x]) >>> 0
    }

    return ret
}

function compl32(v) {
    return (v ^ 0xffffffff) >>> 0
}

function int2ip(ip) {
    let ret = (ip & 255) >>> 0
    let ipv4 = ip >>> 8

    for (let x = 0; x < 3; x++) {
        ret = ((ipv4 & 255) >>> 0) + '.' + ret
        ipv4 = ipv4 >>> 8
    }

    return ret
}

return L.Class.extend({
    getRange: function (ip, s, l) {
        const [ipAddress, prefixLength] = ip.split("/");

        const ipInt = ip2int(ipAddress);
        const netmask = compl32(2 ** (32 - prefixLength) - 1);
        const network = (ipInt & netmask) >>> 0;
        const broadcast = (network | compl32(netmask)) >>> 0;
        let start = (network | ((ip2int(s) & compl32(netmask)) >>> 0)) >>> 0;
        let limit = network + 1;

        if (start < limit) {
            start = limit;
        }

        let end = start + Number(l);
        limit = (((network | compl32(netmask)) >>> 0) - 1) >>> 0;
        if (end > limit) {
            end = limit;
        }

        return {
            'ip': int2ip(ipInt),
            'netmask': int2ip(netmask),
            'broadcast': int2ip(broadcast),
            'network': int2ip(network)+'/'+prefixLength,
            'start': int2ip(start),
            'end': int2ip(end)
        };
    }
})
