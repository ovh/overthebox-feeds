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

    load: function () {
        return Promise.all([
            uci.load('network')
        ]);
    },

    retrieveInterfaces: function(network) {
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

        graph.svg.appendChild(
            otbsvg.createPolyLineElem(
                device,
                otbgraph.stringToColour(device),
                0.6
            )
        );

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

    pollData: function() {
        poll.add(L.bind(function () {
            const rpcStats = otbrpc.realtimeStats();

            for (const {name, sets, graphs} of this.datapoints) {
                L.resolveDefault(rpcStats('interface', name), []).then(
                    rpc => {
                        const deviceStats = rpc.map(st => [[st[0],st[1]], [st[0],st[3]]]);

                        for (const [index, stats] of deviceStats.entries()) {
                            for (const [i, data] of stats.entries()) {
                                // Skip overlapping entries
                                if (data[0] < sets[i].lastUpdate) {
                                    // We are at last stats index
                                    // it's mean we did not push any new data
                                    if (index+1 === deviceStats.length) {
                                        // If there is no data in the set, there is nothing to do
                                        if (Math.max(...set[i].points) === 0) {
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
                                const delta = data[0] - deviceStats[index-1][i][0];
                                if (delta) {
                                    value = (value - deviceStats[index-1][i][1]) / delta
                                }

                                sets[i] = otbgraph.updateSet(sets[i], value, graphs[i].smoothRatio);
                            }
                        }

                        // Redraw
                        for (const [i, set] of sets.entries()) {
                            graphs[i].hscale.ratio = otbgraph.computeHscale(graphs[i].height, set.peak);

                            let curve = '0,' + graphs[i].height;

                            for (const [pos, p] of set.points.entries()) {
                                let x = pos*graphs[i].step,
                                    y = otbgraph.computeHpoint(graphs[i].height, graphs[i].hscale.ratio, p)
                                curve += ' ' + x + ',' + y;

                                // Last point, curve cloture
                                if (pos === (set.points.length - 1)) {
                                    curve += ' ' + graphs[i].width + ',' + y + ' ' + graphs[i].width + ',' + graphs[i].height;
                                }
                            }

                            // Save curve redraw
                            graphs[i].svg.getElementById(name).setAttribute('points', curve);

                            // Save labels
                            graphs[i].hscale.hlabels = otbgraph.computeHlabels(graphs[i].height, graphs[i].hscale.ratio);

                            // Set legends
                            otbgraph.setLegends(graphs[i].svg, graphs[i].hscale.hlabels, graphs[i].wscale);
                        }
                    }
                )
            }
        }, this), this.datapoints[0].graphs[0].wscale.interval);
    },

    render: function (data) {
        // Check if this render is executed for the first time
        if (!this.pollIsActive) {
            const devices = this.retrieveInterfaces(data[0]),
                box = E('div'),
                tabs = [E('div'),E('div')];

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
                        peak:1,
                        // JS date are in ms, but we use s
                        updateTime: (Math.floor(Date.now() / 1000) - 120)
                    };

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
