'use strict';

'require ui';

// Some utils to format data for luci-mod-overthebox

return L.Class.extend({
    // Format Local Time
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

    // Format CPU Load
    formatLoad: function (load) {
        return Array.isArray(load) ? '%.2f, %.2f, %.2f'.format(
            load[0] / 65535.0,
            load[1] / 65535.0,
            load[2] / 65535.0
        ) : null
    },

    // Format ethernet speed
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

    // Format model
    // Return a shorter model version
    formatModel: function (model) {
        switch (model) {
            case "OVH SAS OverTheBox V2B":
                return "OTB v2b"
            case "PC Engines PC Engines apu4":
                return "OTB v2c";
            case "MZ10 MZ10":
                return "OTB v3";
            default:
                if (/qemu/ig.test(model)) {
                    return "QEMU"
                }

                return model
        }
    },

    // Create tabular data
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

    // Create a collapsible element using html details markup
    createNetDetailsElem: function (name, details) {
        const store = 'netmapDetails';

        // Manage collapse state
        if (!window.sessionStorage.getItem(store)) {
            window.sessionStorage.setItem(store, JSON.stringify({ [name]: false }));
        }

        let collapse = E('details', { 'class': 'network-content-details' }, [
            E('summary', '\u2716'),
            E('div', details)
        ]);

        let cState = JSON.parse(window.sessionStorage.getItem(store));
        collapse.open = cState[name];

        collapse.addEventListener('click', function () {
            let cState = JSON.parse(window.sessionStorage.getItem(store));
            cState[name] = !cState[name];
            window.sessionStorage.setItem(store, JSON.stringify(cState));
        });

        return collapse;
    },

    // Create a luci ifacebox elements
    // Head and body should be array
    createIfaceElem: function (head, body) {
        let box = E('div', { 'class': 'ifacebox', 'style': 'margin:.35em;min-width:125px;max-width:450px' });

        box.appendChild(E('div', { 'class': 'ifacebox-head', 'style': 'font-weight:bold' }, head))
        box.appendChild(E('div', { 'class': 'ifacebox-body' }, body))

        return box
    },

    // Create a select element
    createSelectElem: function (options) {
        let select = E('select', { 'class': 'cbi-input-select' })
        for (let key in options) {
            select.appendChild(E('option', { 'value': key }, options[key]))
        }
        return select;
    },

    // Create a simple Luci modal
    // A simple modal with a title, a message and a button OK to close it
    createSimpleModal: function (title, message) {
        return ui.showModal(title, [
            E('span', message),
            E('div', { 'class': 'center' }, [
                E('button', {
                    'class': 'btn cbi-button',
                    'click': () => {
                        ui.hideModal();
                        location.reload();
                    }
                }, 'Ok'),
            ])
        ]);
    },

    // Create a blocking Luci modal
    // A modal with a title and a message which block page content
    createBlockingModal: function (title, message) {
        return ui.showModal(title, [
            E('span', message),
        ]);
    },

    // create a status bar
    // Don't forget to import relevant css
    createStatusBar: function (steps) {
        const bar = E('div', { 'class': 'statusDiv' }, [
            E('div', { 'class': 'statusBar' })
        ]),
            progress = E('div', { 'class': 'progress' }),
            points = E('div', { 'class': 'steps' });

        if (!steps.length) {
            return bar;
        }

        let valid = 0;

        // Populate steps
        for (let step of steps) {
            let s = E('div', { 'class': 'point' }, [
                E('div', { 'id': step.id, 'class': 'step ' + step.state }),
                E('span', step.name)
            ])

            points.appendChild(s)

            if (step.state) {
                valid++;
            }
        }

        // Calculate progress
        let p = ((valid - 1) * (80 / (steps.length - 1)));
        progress.appendChild(E('div', { 'class': 'percent', 'style': 'width:' + p + '%' }));

        bar.appendChild(progress);
        bar.appendChild(points);
        return bar;
    }
});
