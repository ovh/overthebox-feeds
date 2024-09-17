'use strict';
'require baseclass';
'require network';
'require view';
'require poll';
'require request';
'require dom';
'require ui';
'require uci';
'require fs';
'require tools.overthebox.graph as otbgraph';
'require tools.overthebox.svg as otbsvg';
'require tools.overthebox.rpc as otbrpc';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/graph.css')
}));

return baseclass.extend({
    title: _('Realtime Traffic'),
    pollIsActive: false,
    datapoints: [],
    aggregates: [],

    load: function () {
        return Promise.all([
            network.getNetworks(),
            uci.load('network')
        ]);
    },

    retrieveInterfaces: function (nets) {
        let itfs = [];

        for (const net of nets) {
            const device = net.getL3Device();

            if (!device) {
                continue;
            }

            const itf = {
                name: net.getName(),
                device: device.device,
            };

            if (!net.isUp() || itf.device === "lo") {
                continue;
            }

            const label = uci.get('network', itf.name, 'label');
            if (label) {
                itf.name = label;
            }

            itf.multipath = uci.get('network', itf.name, 'multipath');

            itfs.push(itf)
        }

        return itfs;
    },

    createGraph: function (device, type) {
        // Introduce some responsiveness
        const view = document.querySelector('#view'),
            regexp = /\.|\-/g,
            id = device.replace(regexp, '') + '_' + type,
            graph = otbgraph.newGraph(id, view.offsetWidth);

        graph.svg = otbsvg.createBackground(id);

        if (device === 'multipath') {
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

    pollData: function () {
        poll.add(L.bind(function () {
            const rpcStats = otbrpc.realtimeStats(),
                tasks = [];

            for (const { name, device, sets, graphs } of this.datapoints) {
                tasks.push(L.resolveDefault(rpcStats('interface', device), []).then(
                    rpc => {
                        const deviceStats = rpc.map(st => [[st[0], st[1]], [st[0], st[3]]]);
                        otbgraph.updateSets(graphs, sets, deviceStats);

                        // Redraw
                        for (const [i, set] of sets.entries()) {
                            otbgraph.drawSimple(graphs[i], set);
                        }
                    }
                ));
            }

            Promise.all(tasks).then(
                // Compute aggregate
                () => {
                    for (const [index, graph] of this.aggregates.entries()) {
                        let names = [];
                        let lines = [];

                        for (const { name, device, multipath, sets, graphs } of this.datapoints) {
                            if (!multipath) {
                                continue;
                            }

                            names.push(graph.id + '_' + name);
                            lines.push(sets[index].points.slice());
                        }

                        // Redraw
                        otbgraph.drawAggregate(graph, names, lines);
                    }
                }
            )
        }, this), this.aggregates[0].wscale.interval);
    },

    render: function (data) {
        // Check if this render is executed for the first time
        if (!this.pollIsActive) {
            const itfs = this.retrieveInterfaces(data[0]),
                box = E('div'),
                tabs = [E('div'), E('div')];

            // Init aggregate graph
            this.aggregates = [
                this.createGraph('multipath', 'rx'),
                this.createGraph('multipath', 'tx')
            ];

            for (const [i, g] of this.aggregates.entries()) {
                tabs[i].appendChild(E('div', { 'data-tab': 'multipath', 'data-tab-title': 'multipath', }, [
                    E('div', { 'class': 'otb-graph' }, [g.svg]),
                    E('div', { 'class': 'right' }, E('small', { 'id': g.wscale.id }, '-'))
                ]));
            }

            // Init device graph
            for (const itf of itfs) {
                const d = {
                    name: itf.name,
                    device: itf.device,
                    multipath: false,
                    sets: new Array(2),
                    graphs: [
                        this.createGraph(itf.name, 'rx'),
                        this.createGraph(itf.name, 'tx')
                    ]
                };

                for (const [i, g] of d.graphs.entries()) {
                    d.sets[i] = {
                        points: new Array(g.points).fill(0),
                        peak: 1,
                        avg: 0,
                        // JS date are in ms, but we use s
                        lastUpdate: (Math.floor(Date.now() / 1000) - 120)
                    };

                    if (itf.multipath && itf.multipath !== "off") {
                        // Append line to aggregate
                        this.aggregates[i].svg.appendChild(
                            otbsvg.createPolyLineElem(
                                this.aggregates[i].id + '_' + d.name,
                                otbgraph.stringToColour(d.name),
                                0.6
                            )
                        );
                        d.multipath = true;
                    }

                    tabs[i].appendChild(E('div', { 'data-tab': d.name, 'data-tab-title': d.name }, [
                        E('div', { 'class': 'otb-graph' }, [g.svg]),
                        E('div', { 'class': 'right' }, E('small', { 'id': g.wscale.id }, '-'))
                    ]));
                }

                this.datapoints.push(d)
            }

            let title = _('Download');
            for (const tab of tabs) {
                box.appendChild(E('h2', title));
                box.appendChild(tab);
                ui.tabs.initTabGroup(box.lastElementChild.childNodes);
                title = _('Upload');
            }

            this.pollIsActive = 1;
            this.pollData();

            return box;
        }
    }
});
