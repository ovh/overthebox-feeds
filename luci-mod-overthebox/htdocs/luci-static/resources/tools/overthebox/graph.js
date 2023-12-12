'use strict';

return L.Class.extend({
    newGraph: function (id, viewWidth) {
        const graph = {
            id: id,
            // Graph scale
            // 500 - 2
            width: 498,
            // 300 - 2
            height: 298,
            step: 5,
            // Number of points in graph
            // Math.floor(width / step)
            points: 99,
            // Smooth by 5%
            smoothRatio: 99 * 0.05,
            // Height Scale
            hscale: {
                // Hscale ratio
                ratio: 149,
                hlabels: {
                    l25: 149 * 0.25,
                    l50: 149 * 0.5,
                    l75: 149 * 0.75
                }
            },
            // Width Scale
            wscale: {
                id: id + '_scale',
                // poll interval in seconds
                interval: 3,
                // time between each data point
                // points / 60
                timeframe: 99 / 60
            },
            // SVG Data
            svg: '',
        }

        graph.width = viewWidth - 2;
        graph.points = Math.floor(graph.width / graph.step);
        graph.smoothRatio = graph.points * 0.05
        graph.wscale.timeframe = graph.points / 60;
        return graph
    },

    stringToColour: function (str) {
        if (str == "free1")
            return "BlueViolet";
        if (str == "ovh1")
            return "DeepSkyBlue";
        if (str == "ovh2")
            return "LightGreen";

        if (str == "if1")
            return "PowderBlue";
        if (str == "if2")
            return "PaleGreen";
        if (str == "if3")
            return "YellowGreen";
        if (str == "if4")
            return "SeaGreen";
        if (str == "if5")
            return "SteelBlue";
        if (str == "if6")
            return "SlateBlue";
        if (str == "if7")
            return "PaleTurquoise";
        if (str == "if8")
            return "BlueViolet";

        if (str == "tun0")
            return "Mediumslateblue";
        if (str == "xtun0")
            return "FireBrick";

        // Generate a color folowing the name
        Math.seedrandom(str);
        var rand = Math.random() * Math.pow(255, 3);
        Math.seedrandom(); // don't leave a non-random seed in the generator
        for (var i = 0, color = "#"; i < 3; color += ("00" + ((rand >> i++ * 8) & 0xFF).toString(16)).slice(-2));
        return color;
    },

    // Compute a height scale based on peak data
    computeHscale: function (graph, peak) {
        const s = Math.floor(Math.log2(peak)),
            d = Math.pow(2, s - (s % 10)),
            m = peak / d,
            n = (m < 5) ? 2 : ((m < 50) ? 10 : ((m < 500) ? 100 : 1000)),
            p = peak + (n * d) - (peak % (n * d));

        graph.hscale.ratio = graph.height / p;
    },

    // Compute Hlabels
    computeHlabels: function (graph) {
        const v = (graph.height / graph.hscale.ratio);

        for (let i = 25; i < 100; i += 25) {
            graph.hscale.hlabels['l' + i] = v * (i / 100)
        }
    },

    // Scale point based on Hscale
    computeHpoint: function (graph, point) {
        let y = graph.height - Math.floor(point * graph.hscale.ratio);
        return isNaN(y) ? graph.height : y;
    },

    // Set Hlabel and time windows in svg node
    setLegends: function (graph, peak, avg) {
        for (let i = 25; i < 100; i += 25) {
            graph.svg.getElementById(graph.id + '_label_' + i).firstChild.data = this.rate(graph.hscale.hlabels['l' + i]).join('');
        }

        graph.svg.getElementById(graph.id + '_label_peak').firstChild.data = 'peak: ' + this.rate(peak).join('');
        graph.svg.getElementById(graph.id + '_label_avg').firstChild.data = 'avg: ' + this.rate(avg / graph.points).join('');

        graph.svg.parentNode.parentNode.querySelector('#' + graph.wscale.id).firstChild.data = _('(%d minute window, %d second interval)').format(graph.wscale.timeframe, graph.wscale.interval);
    },

    // Format bandwidth data
    rate: function rate(n, br) {
        n = (n || 0).toFixed(2);
        return ['%1024.2mbit/s'.format(n * 8), br ? E('br') : ' ', '(%1024.2mB/s)'.format(n)]
    },

    // insert a new value in a set
    insertValue: function (set, value, ratio) {
        const oldestPoint = set.points.shift();
        set.avg -= oldestPoint

        // Check if we need to reset peak
        if (oldestPoint >= set.peak) {
            set.peak = 1
            for (const p of set.points) {
                set.peak = p > set.peak ? p : set.peak
            }
        }

        // Calculate exponentially moving average
        const lastPoint = set.points[set.points.length - 1],
            newPoint = lastPoint + (value - lastPoint) / ratio;

        set.points.push(newPoint);
        set.avg += newPoint

        // Change peak value if needed
        set.peak = newPoint > set.peak ? newPoint : set.peak;
    },

    // Update a set with new entries from a rpc call
    updateSets: function (graphs, sets, deviceStats) {
        for (const [index, stats] of deviceStats.entries()) {
            for (const [i, data] of stats.entries()) {
                // Skip overlapping entries
                if (data[0] < sets[i].lastUpdate) {
                    // We are at last stats index
                    // it's mean we did not push any new data
                    if (index + 1 === deviceStats.length) {
                        // last point was set less than 5 seconds ago
                        if ((data[0] + 5) - sets[i].lastUpdate >= 0) {
                            continue;
                        }

                        // If there is no data in the set, there is nothing to do
                        if (Math.max(...sets[i].points) === 0) {
                            continue;
                        }

                        // If we still have data we need to fill set with 0 values
                        for (let a = 0; a < 4; a++) {
                            this.insertValue(sets[i], 0, graphs[i].smoothRatio);
                        }
                        sets[i].lastUpdate += 3;
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
                    let v = (value - deviceStats[index - 1][i][1]) / delta
                    if (v >= 0) {
                        value = v
                    }
                }

                this.insertValue(sets[i], value, graphs[i].smoothRatio);
            }
        }
    },

    // Draw curve
    drawCurve: function (graph, points) {
        let curve = '0,' + graph.height;

        for (const [pos, p] of points.entries()) {
            let x = pos * graph.step,
                y = this.computeHpoint(graph, p)
            curve += ' ' + x + ',' + y;

            // Last point, curve cloture
            if (pos === (points.length - 1)) {
                curve += ' ' + graph.width + ',' + y + ' ' + graph.width + ',' + graph.height;
            }
        }

        return curve
    },

    // Draw a simple graph from a set of points
    drawSimple: function (graph, set) {
        this.computeHscale(graph, set.peak);

        // Save curve redraw
        const curve = this.drawCurve(graph, set.points)
        graph.svg.getElementById(graph.id).setAttribute('points', curve);

        // Save labels
        this.computeHlabels(graph);

        // Set legends
        this.setLegends(graph, set.peak, set.avg);
    },

    // Draw an aggregates graph
    drawAggregate: function (graph, names, lines) {
        let peak = 1;
        let avg = 1;

        for (let [i, line] of lines.entries()) {
            // Aggregate lines
            // To have a correct stack, the highest line should be the first one
            lines[i] = line = line.map((x, y) => {
                const l = lines.slice(i + 1);
                for (let j = 0; j < l.length; j++) {
                    x += l[j][y];
                }

                // Set peak and avg in the first run
                if (i === 0) {
                    peak = x > peak ? x : peak;
                    avg += x;
                }

                return x
            });

            // First line we should compute hscale
            if (i === 0) {
                this.computeHscale(graph, peak);
            }

            // Save curve redraw
            const curve = this.drawCurve(graph, line)
            graph.svg.getElementById(names[i]).setAttribute('points', curve);

            // Thats the first line we should add global curve
            if (i === 0) {
                graph.svg.getElementById(graph.id).setAttribute('points', curve);
            }

            // Compute labels
            this.computeHlabels(graph);

            // Update legends
            this.setLegends(graph, peak, avg);
        }
    }
});
