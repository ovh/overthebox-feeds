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

    formatEthSpeed: function (speed, duplex) {
        if (speed && duplex) {
            let d = (duplex == 'half') ? '\u202f(H)' : '',
                e = E('span', { 'title': _('Speed: %d Mibit/s, Duplex: %s').format(speed, duplex) });

            switch (speed) {
                case 10: e.innerText = '10\u202fM' + d; break;
                case 100: e.innerText = '100\u202fM' + d; break;
                case 1000: e.innerText = '1\u202fGbE' + d; break;
                case 2500: e.innerText = '2.5\u202fGbE'; break;
                case 5000: e.innerText = '5\u202fGbE'; break;
                case 10000: e.innerText = '10\u202fGbE'; break;
                case 25000: e.innerText = '25\u202fGbE'; break;
                case 40000: e.innerText = '40\u202fGbE'; break;
                default: e.innerText = '%d\u202fMbE%s'.format(speed, d);
            }

            return e;
        }

        return _('No link');
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
            E('summary', { 'class': 'otb-summary', 'style': 'background-color:' + color }, summary),
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

    // This create a luci ifacebox elements
    // Head and body should be array
    createIfaceElem: function (head, body) {
        let box = E('div', { 'class': 'ifacebox', 'style': 'margin:.35em;min-width:125px;max-width:450px' });

        box.appendChild(E('div', { 'class': 'ifacebox-head', 'style': 'font-weight:bold' }, head))
        box.appendChild(E('div', { 'class': 'ifacebox-body' }, body))

        return box
    },

    // This create a polyline element
    createPolyLineElem: function(id, color, opacity) {
        var line = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
        line.setAttributeNS(null, 'id', id);
        line.setAttributeNS(null, 'style', 'fill:' + color + ';fill-opacity:' + opacity + ';');

        return line;
    },

    // This create a text element
    createTextElem: function(x_pos, y_pos) {
        var text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('x', x_pos);
        text.setAttribute('y', y_pos);
        text.setAttribute('style', 'fill:#999999; font-size:9pt; font-family:sans-serif; text-shadow:1px 1px 1px #000');

        return text;
    },

    // This create a line element
    createLineElem: function(x1_pos, y1_pos, x2_pos, y2_pos) {
        var line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        line.setAttribute('x1', x1_pos);
        line.setAttribute('y1', y1_pos);
        line.setAttribute('x2', x2_pos);
        line.setAttribute('y2', y2_pos);
        line.setAttribute('style', 'stroke:black;stroke-width:0.1');

        return line;
    }
});
