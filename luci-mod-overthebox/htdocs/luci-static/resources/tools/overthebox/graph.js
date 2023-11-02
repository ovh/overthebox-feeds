'use strict';

return L.Class.extend({
    newGraph: function (name, type, viewWidth) {
        const graph = {
            name: name,
            type: type,
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
                name: 'scale',
                // poll interval in seconds
                interval: 2,
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
        graph.wscale.name = graph.name + '_' + graph.type + '_scale';
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
            return "DimGrey";
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

        return graph.height / p;
    },

    // Compute Hlabels
    computeHlabels: function (graph) {
        const v = (graph.height / graph.hscale.ratio);

        return {
            l25: v * 0.25,
            l50: v * 0.5,
            l75: v * 0.75
        }
    },

    // Scale point based on Hscale
    computeHpoint: function (graph, point) {
        let y = height - Math.floor(point * graph.hscale.ratio);
        return isNaN(y) ? graph.height : y;
    },

    // Set Hlabel and time windows in svg node
    setLegends: function (graph) {
        for (let i = 25; i < 100; i += 25) {
            graph.svg.getElementById('label_' + i).firstChild.data = this.rate(graph.hscale.hlabels['l' + i]).join('');
        }

        graph.svg.parentNode.parentNode.querySelector('#' + graph.wscale.name).firstChild.data = _('(%d minute window, %d second interval)').format(graph.wscale.timeframe, graph.wscale.interval);
    },

    // Format bandwidth data
    rate: function rate(n, br) {
        n = (n || 0).toFixed(2);
        return ['%1024.2mbit/s'.format(n * 8), br ? E('br') : ' ', '(%1024.2mB/s)'.format(n)]
    },

    // Update set with a new value
    updateSet: function (set, value, ratio) {
        const oldestPoint = set.points.shift();

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

        // Change peak value if needed
        set.peak = newPoint > set.peak ? newPoint : set.peak;

        return set
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
    }
});
