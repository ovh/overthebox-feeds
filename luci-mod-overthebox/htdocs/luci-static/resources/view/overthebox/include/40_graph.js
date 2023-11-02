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


return baseclass.extend({
    title: _('Realtime Traffic'),
    pollIsActive: false,
    datapoints: [],
    aggregates: [],

    load: function () {
        return Promise.all([
            uci.load('network')
        ]);
    },

    retrieveInterfaces: function (network) {
        const interfaces = uci.sections('network', 'interface');

        let devs = [];
        // Search for interfaces which use multipath
        for (const itf of interfaces) {
            if (!itf.multipath || itf.multipath === "off") {
                continue
            }

            devs.push(itf.device);
        }

        return devs;
    },

    createGraph: function (device, type) {
        // Introduce some responsiveness
        const view = document.querySelector('#view');

        const graph = otbgraph.newGraph(device, type, view.offsetWidth);
        graph.svg = otbsvg.createBackground();

        if (device === 'all') {
            let line = otbsvg.createPolyLineElem(
                device,
                'DimGray',
                0
            );
            // Override style
            line.setAttributeNS(null, 'style', 'stroke:DimGray;stroke-width:3;stroke-linecap="round";fill:;fill-opacity:0;');
            graph.svg.appendChild(line);
        } else {
            graph.svg.appendChild(
                otbsvg.createPolyLineElem(
                    device,
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

                        for (const [index, stats] of deviceStats.entries()) {
                            for (const [i, data] of stats.entries()) {
                                // Skip overlapping entries
                                if (data[0] < sets[i].lastUpdate) {
                                    // We are at last stats index
                                    // it's mean we did not push any new data
                                    if (index + 1 === deviceStats.length) {
                                        // If there is no data in the set, there is nothing to do
                                        if (Math.max(...sets[i].points) === 0) {
                                            continue;
                                        }

                                        // If we still have data we need to fill set with 0 values
                                        for (let a = 0; a < 4; a++) {
                                            sets[i] = otbgraph.updateSet(sets[i], 0, graphs[i].smoothRatio);
                                        }
                                        sets[i].updateTime += 3;
                                    }

                                    continue;
                                }

                                // Update time
                                sets[i].lastUpdate = data[0];

                                // First entry we just update time
                                if (index === 0) {
                                    continue;
                                }

                                let value = data[1];

                                // Normalize diff against time interval
                                const delta = data[0] - deviceStats[index - 1][i][0];
                                if (delta) {
                                    value = (value - deviceStats[index - 1][i][1]) / delta
                                }

                                sets[i] = otbgraph.updateSet(sets[i], value, graphs[i].smoothRatio);
                            }
                        }

                        // Redraw
                        for (const [i, set] of sets.entries()) {
                            graphs[i].hscale.ratio = otbgraph.computeHscale(graphs[i], set.peak);

                            // Save curve redraw
                            const curve = otbgraph.drawCurve(graphs[i], set.points)
                            graphs[i].svg.getElementById(name).setAttribute('points', curve);

                            // Save labels
                            graphs[i].hscale.hlabels = otbgraph.computeHlabels(graphs[i]);

                            // Set legends
                            otbgraph.setLegends(graphs[i]);
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
                        let peak = 1;

                        for (const { name, sets, graphs } of this.datapoints) {
                            names.push(name);
                            lines.push(sets[index].points);

                            // First element we just push data
                            if (lines.length === 1) {
                                peak = sets[index].peak
                                continue
                            }

                            // Aggregate lines
                            for (let i = 0; i < sets[index].points.length; i++) {
                                lines[lines.length - 1][i] += lines[lines.length - 2][i];
                                peak = lines[lines.length - 1][i] > peak ? lines[lines.length - 1][i] : peak
                            }
                        }

                        // Redraw
                        graph.hscale.ratio = otbgraph.computeHscale(graph, peak);

                        for (const [i, line] of lines.entries()) {
                            // Save curve redraw
                            const curve = otbgraph.drawCurve(graph, line)
                            graph.svg.getElementById(names[i]).setAttribute('points', curve);

                            // Thats the last line we should add global curve
                            if (i === lines.length - 1) {
                                graph.svg.getElementById('all').setAttribute('points', curve);
                            }

                            // Save labels
                            graph.hscale.hlabels = otbgraph.computeHlabels(graph);

                            // Set legends
                            otbgraph.setLegends(graph);
                        }
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

            // Init aggregate graph
            this.aggregates = [
                this.createGraph('all', 'rx'),
                this.createGraph('all', 'tx')
            ];

            for (const [i, g] of this.aggregates.entries()) {
                tabs[i].appendChild(E('div', { 'data-tab': 'all', 'data-tab-title': 'all' }, [
                    g.svg,
                    E('div', { 'class': 'right' }, E('small', { 'id': g.wscale.name }, '-'))
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
                        // JS date are in ms, but we use s
                        lastUpdate: (Math.floor(Date.now() / 1000) - 120)
                    };

                    // Append line to aggregate
                    this.aggregates[i].svg.appendChild(
                        otbsvg.createPolyLineElem(
                            device,
                            otbgraph.stringToColour(device),
                            0.6
                        )
                    );

                    tabs[i].appendChild(E('div', { 'data-tab': device, 'data-tab-title': device }, [
                        g.svg,
                        E('div', { 'class': 'right' }, E('small', { 'id': g.wscale.name }, '-'))
                    ]));
                }

                this.datapoints.push(d)
            }

            let title = 'Download';
            for (const tab of tabs) {
                box.appendChild(E('h2', title));
                box.appendChild(tab);
                ui.tabs.initTabGroup(box.lastElementChild.childNodes);
                title = 'Upload';
            }

            this.pollIsActive = 1;
            this.pollData();

            return box;
        }
    }
});
