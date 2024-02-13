'use strict';
'require view';
'require dom';
'require poll';
'require request';
'require ui';
'require rpc';
'require network';
'require tools.overthebox.include as include';
'require tools.overthebox.graph as otbgraph';
'require tools.overthebox.svg as otbsvg';
'require tools.overthebox.rpc as otbrpc';
'require fs';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/custom.css')
}));

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/graph.css')
}));

return view.extend({
    pollIsActive: false,
    datapoints: [],
    aggregates: [],
    sources: [],

    load: function () {
        // Include seedrandom
        include.script(L.resource("seedrandom.js"));
        const rpcDHCP = otbrpc.dhcpLeases();

        return Promise.all([
            fs.exec('/bin/bandwidth', ['fetch', 'json'], null),
            rpcDHCP()
        ]);
    },

    createGraph: function (device, type) {
        // Introduce some responsiveness
        const view = document.querySelector('#view'),
            regexp = /\.|\-/g,
            id = device.replace(regexp, '') + '_' + type,
            graph = otbgraph.newGraph(id, view.offsetWidth);

        graph.svg = otbsvg.createBackground(id);

        if (device === 'all') {
            let line = otbsvg.createPolyLineElem(
                id,
                'DimGray',
                0
            );
            // Override style
            line.removeAttributeNS(null, 'style');
            line.setAttributeNS(null, 'class', 'otb-graph-mline');
            graph.svg.appendChild(line);
        } else {
            graph.svg.appendChild(
                otbsvg.createPolyLineElem(
                    id,
                    otbgraph.stringToColour(device),
                    0.6
                )
            );
        }

        // Plot height time interval lines
        // With a width of 498 and a step of 5 we are just looping once here
        const intv = graph.step * 60;
        for (let i = graph.width % intv; i < graph.width; i += intv) {
            // Create Text element
            // With a width of 498 and a step of 5 that's 1
            const label = Math.round((graph.width - i) / graph.step / 60) + 'm';

            // Append lines
            graph.svg.appendChild(otbsvg.createLineElem(i, 0, i, '100%'));
            graph.svg.appendChild(otbsvg.createTextElem(i + 5, 15, label));
        }

        return graph;
    },

    updateTable: function (hosts) {
        const rows = [];

        // Sort by decreasing rx traffic
        hosts.sort((a, b) => (b.rx + b.tx) - (a.rx + a.tx));

        for (const host of hosts) {
            rows.push([
                host.hostname,
                host.ip,
                host.mac,
                otbgraph.rate(host.rx).join(''),
                otbgraph.rate(host.tx).join('')
            ]);
        }

        cbi_update_table('#lanTraffic', rows, E('em', _('No information available')));
    },

    pollData: function () {
        poll.add(L.bind(function () {
            fs.exec('/bin/bandwidth', ['fetch', 'json'], null).then(
                data => {
                    const hosts = JSON.parse(data.stdout),
                        t = (Math.floor(Date.now() / 1000));


                    for (const { name, sets, lastValues, graphs } of this.datapoints) {
                        for (const host of hosts) {
                            const id = host.hostname || 'ip' + host.ip;
                            if (id != name) {
                                continue;
                            }

                            let rx = lastValues[lastValues.length - 1][0][1],
                                tx = lastValues[lastValues.length - 1][1][1];

                            lastValues.push([[t, host.rx / 8], [t, host.tx / 8]]);

                            host.rx = (host.rx / 8) - rx;
                            host.tx = (host.tx / 8) - tx;

                            // Keep size in check
                            if (lastValues.length > 5) {
                                lastValues.shift();
                            }

                            otbgraph.updateSets(graphs, sets, lastValues);

                            // Redraw
                            for (const [i, set] of sets.entries()) {
                                otbgraph.drawSimple(graphs[i], set);
                            }

                            break;
                        }
                    }

                    // Update table
                    this.updateTable(hosts);
                }
            )
                .then(
                    // Compute aggregate
                    () => {
                        for (const [index, graph] of this.aggregates.entries()) {
                            let names = [];
                            let lines = [];

                            for (const { name, sets, graphs } of this.datapoints) {
                                names.push(graph.id + '_' + name);
                                lines.push(sets[index].points.slice());
                            }

                            // Redraw
                            otbgraph.drawAggregate(graph, names, lines);
                        }
                    }
                )
        }, this), this.aggregates[0].wscale.interval)
    },

    render: function (data) {
        const hosts = JSON.parse(data[0].stdout),
            gdiv = E('div'),
            tabs = [E('div'), E('div')];

        // Init aggregate graph
        this.aggregates = [
            this.createGraph('all', 'rx'),
            this.createGraph('all', 'tx')
        ];

        for (const [i, g] of this.aggregates.entries()) {
            tabs[i].appendChild(E('div', { 'data-tab': 'all', 'data-tab-title': 'all', }, [
                E('div', { 'class': 'otb-graph' }, [g.svg]),
                E('div', { 'class': 'right' }, E('small', { 'id': g.wscale.id }, '-'))
            ]));
        }

        // Init device graph
        for (const host of hosts) {
            // JS date are in ms, but we use s
            const t = (Math.floor(Date.now() / 1000) - 120),
                // We need to start with a letter for queryselector
                name = host.hostname || 'ip' + host.ip,
                d = {
                    name: name,
                    sets: new Array(2),
                    lastValues: [[[t, host.rx / 8], [t, host.tx / 8]]],
                    graphs: [
                        this.createGraph(name, 'rx'),
                        this.createGraph(name, 'tx')
                    ]
                };

            for (const [i, g] of d.graphs.entries()) {
                d.sets[i] = {
                    points: new Array(g.points).fill(0),
                    peak: 1,
                    avg: 0,
                    lastUpdate: t
                };

                // Append line to aggregate
                this.aggregates[i].svg.appendChild(
                    otbsvg.createPolyLineElem(
                        this.aggregates[i].id + '_' + name,
                        otbgraph.stringToColour(name),
                        0.6
                    )
                );

                tabs[i].appendChild(E('div', { 'data-tab': name, 'data-tab-title': name }, [
                    E('div', { 'class': 'otb-graph' }, [g.svg]),
                    E('div', { 'class': 'right' }, E('small', { 'id': g.wscale.id }, '-'))
                ]));
            }

            this.datapoints.push(d)
        }

        let title = _('Download');
        for (const tab of tabs) {
            gdiv.appendChild(E('h2', title));
            gdiv.appendChild(tab);
            ui.tabs.initTabGroup(gdiv.lastElementChild.childNodes);
            title = _('Upload');
        }

        const box = E([], [
            gdiv,
            E('h2', 'Details'),
            E('div', { 'class': 'cbi-section-node' }, [
                E('table', { 'class': 'table', 'id': 'lanTraffic' }, [
                    E('tr', { 'class': 'tr table-titles' }, [
                        E('th', { 'class': 'th' }, [_('Host')]),
                        E('th', { 'class': 'th' }, [_('IPv4')]),
                        E('th', { 'class': 'th' }, [_('MAC')]),
                        E('th', { 'class': 'th' }, [_('Download')]),
                        E('th', { 'class': 'th' }, [_('Upload')]),
                    ])
                ])
            ])
        ]);

        if (!this.pollIsActive) {
            this.pollIsActive = true;
            this.pollData();
        }

        return box;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
})
