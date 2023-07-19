'use strict';

// Some utils to format data for luci-mod-overthebox

return L.Class.extend({
    formatLocalTime: function (localtime) {
        let date = new Date(localtime * 1000);

        return '%04d-%02d-%02d %02d:%02d:%02d'.format(
            date.getUTCFullYear(),
            date.getUTCMonth() + 1,
            date.getUTCDate(),
            date.getUTCHours(),
            date.getUTCMinutes(),
            date.getUTCSeconds()
        );
    },

    formatLoad: function (load) {
        return Array.isArray(load) ? '%.2f, %.2f, %.2f'.format(
            load[0] / 65535.0,
            load[1] / 65535.0,
            load[2] / 65535.0
        ) : null
    },

    // We are expecting an array like [name1, value1, name2, value2]
    createTabularElem: function (fields) {
        let table = E('table', { 'class': 'table' });

        for (let i = 0; i < fields.length; i += 2) {
            table.appendChild(E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td left', 'width': '33%' }, [fields[i]]),
                E('td', { 'class': 'td left' }, [(fields[i + 1] != null) ? fields[i + 1] : '?'])
            ]));
        }

        return table;
    },

    // This create a collapsible element using html details markup
    createDetailsElem: function (name, summary, body, color) {
        // Manage collapse state
        if (!window.sessionStorage.getItem('otbCollapse')) {
            window.sessionStorage.setItem('otbCollapse', JSON.stringify({ [name]: false }));
        }

        let collapse = E('details', { 'class': 'otb-details', 'id': name }, [
            E('summary', { 'class': 'otb-summary', 'style':'background-color:'+ color }, summary),
            body
        ]);

        let cState = JSON.parse(window.sessionStorage.getItem('otbCollapse'));
        collapse.open = cState[name];

        collapse.addEventListener('click', function () {
            let cState = JSON.parse(window.sessionStorage.getItem('otbCollapse'));
            cState[name] = !cState[name];
            window.sessionStorage.setItem('otbCollapse', JSON.stringify(cState));
        });

        return collapse;
    },

});
