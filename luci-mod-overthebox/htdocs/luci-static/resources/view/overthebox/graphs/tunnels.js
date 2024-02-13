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
    load: function () {
        return Promise.all([
            network.getDevices()
        ]);
    },

    retrieveInterfaces: function (devices) {
        let devs = [];
        for (const device of devices) {
            // Search for interfaces which are point-to-point
            if (!device.dev || !device.dev.flags || !device.dev.flags.pointtopoint) {
                continue
            }

            devs.push(device.getName());
        }

        return devs;
    },

    createGraph: function (device, type) {
        // Introduce some responsiveness
        const view = document.querySelector('#view');

        const id = device + '_' + type
        const graph = otbgraph.newGraph(id, view.offsetWidth);
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

    pollData: function () {
        poll.add(L.bind(function () {
            const rpcStats = otbrpc.realtimeStats(),
                tasks = [];

            for (const { name, sets, graphs } of this.datapoints) {
                tasks.push(L.resolveDefault(rpcStats('interface', name), []).then(
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

                        for (const { name, sets, graphs } of this.datapoints) {
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
            const devices = this.retrieveInterfaces(data[0]),
                box = E('div'),
                tabs = [E('div'), E('div')];

            // Include seedrandom
            include.script(L.resource("seedrandom.js"))

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
            for (const device of devices) {
                const d = {
                    name: device,
                    sets: new Array(2),
                    graphs: [
                        this.createGraph(device, 'rx'),
                        this.createGraph(device, 'tx')
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

                    // Append line to aggregate
                    this.aggregates[i].svg.appendChild(
                        otbsvg.createPolyLineElem(
                            this.aggregates[i].id + '_' + device,
                            otbgraph.stringToColour(device),
                            0.6
                        )
                    );

                    tabs[i].appendChild(E('div', { 'data-tab': device, 'data-tab-title': device }, [
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
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
