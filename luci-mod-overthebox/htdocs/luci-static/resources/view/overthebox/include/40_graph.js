'use strict';
'require baseclass';
'require network';
'require view';
'require poll';
'require request';
'require dom';
'require ui';
'require uci';
'require rpc';
'require fs';
'require tools.overthebox.graph as otbgraph';
'require tools.overthebox.svg as otbsvg';

var callLuciRealtimeStats = rpc.declare({
    object: 'luci',
    method: 'getRealtimeStats',
    params: ['mode', 'device'],
    expect: { result: [] }
});

var callLuciDeviceStatus = rpc.declare({
    object: 'network.device',
    method: 'status',
    params: ['name'],
    expect: { '': {} }
});

function rate(n, br) {
    n = (n || 0).toFixed(2);
    return ['%1024.2mbit/s'.format(n * 8), br ? E('br') : ' ', '(%1024.2mB/s)'.format(n)]
}

return baseclass.extend({
    title: _('Realtime Traffic'),
    pollIsActive: false,
    graph: {},

    load: function () {
        return Promise.all([
            uci.load('network')
        ]);
    },

    createGraph: function (svgRX, svgTX, network, legendFn) {
        this.graph = {
            // Graph scale
            // 500 - 2
            width: 498,
            // 300 - 2
            height: 298,
            step: 5,
            // Number of points in graph
            // Math.floor(width / step)
            points: 99,
            // smooth by 5%
            smoother: 99 * 0.05,
            // Graph infos
            infos: {
                // Highest data point
                peak: {
                    rx: 1,
                    tx: 1,
                },
                // poll interval in seconds
                interval: 2,
                // time between each data point
                // points / 60
                timeframe: 99 / 60,
                hscale: {
                    rx: 149,
                    tx: 149,
                },
                hlabels: {
                    rx: {
                        l25: 149 * 0.25,
                        l50: 149 * 0.5,
                        l75: 149 * 0.75
                    },
                    tx: {
                        l25: 149 * 0.25,
                        l50: 149 * 0.5,
                        l75: 149 * 0.75
                    }
                }
            },
            // Network devices values
            devices: [],
            // SVG Data
            svgRX: svgRX,
            svgTX: svgTX,
            // Legend
            legend: legendFn
        }

        // Introduce some responsiveness
        let view = document.querySelector('#view');
        this.graph.width = (view.offsetWidth / 2) - 2;
        this.graph.points = Math.floor(this.graph.width / this.graph.step);
        this.graph.smoother = this.graph.points * 0.05
        this.graph.infos.timeframe = this.graph.points / 60;

        const interfaces = uci.sections('network', 'interface');

        // Search for interfaces which use multipath
        for (const itf of interfaces) {
            if (!itf.multipath || itf.multipath === "off") {
                continue
            }

            const dev = itf.device,
                color = otbgraph.stringToColour(dev);

            // Create a new polyline to draw the bandwith
            this.graph.svgRX.appendChild(
                otbsvg.createPolyLineElem(
                    'rx_' + dev,
                    color,
                    0.6
                )
            );

            this.graph.svgTX.appendChild(
                otbsvg.createPolyLineElem(
                    'tx_' + dev,
                    color,
                    0.6
                )
            );

            // Prefill device data
            this.graph.devices.push({
                name: dev,
                points: new Array(this.graph.points).fill({ rx: 0, tx: 0 }),
                peak: { rx: 1, tx: 1 },
                // JS date are in ms, but we use s
                updateTime: (Math.floor(Date.now() / 1000) - 120)
            });
        }

        // Plot horizontal time interval lines
        // With a width of 498 and a step of 5 we are just looping once here
        const intv = this.graph.step * 60;
        for (let i = this.graph.width % intv; i < this.graph.width; i += intv) {
            // Create Text element for download
            // With a width of 498 and a step of 5 that's 1
            let label = Math.round((this.graph.width - i) / this.graph.step / 60) + 'm';

            // Append download line and text to download plot
            this.graph.svgRX.appendChild(otbsvg.createLineElem(i, 0, i, '100%'));
            this.graph.svgRX.appendChild(otbsvg.createTextElem(i + 5, 15, label));

            // Append upload line and text to upload plot
            this.graph.svgTX.appendChild(otbsvg.createLineElem(i, 0, i, '100%'));
            this.graph.svgTX.appendChild(otbsvg.createTextElem(i + 5, 15, label));
        }
    },

    pollData: function () {
        poll.add(L.bind(function () {
            let tasks = [];
            this.graph.devices.forEach(
                device => {
                    tasks.push(L.resolveDefault(callLuciRealtimeStats('interface', device.name), []));
                    tasks.push(L.resolveDefault(callLuciDeviceStatus(device.name, {})));
                }
            );

            return Promise.all(tasks).then(
                L.bind(function (data) {
                    // To get correct index from data
                    let i = 0;

                    let devIndex = 0;
                    let changeGlobalPeak = false;
                    for (const device of this.graph.devices) {
                        const deviceStats = data[i],
                            // Check if device is still connected
                            deviceStatus = data[i + 1];

                        // 2 promises per device
                        i += 2;

                        let changeDevicePeak = false;

                        // Iterate for each seconds we are missing
                        for (var j = 0; j < device.points.length; j++) {
                            // We are trying to get data that are out of bound
                            // If Device is not present (can happens with LTE Key) we need to fill the array
                            if (j >= deviceStats.length && deviceStatus.present) {
                                break;
                            }

                            // Retrieve new data point
                            let currentStat = deviceStats[j];
                            if (typeof currentStat !== 'undefined') {
                                // Skip overlapping entries
                                if (currentStat[0] <= device.updateTime) {
                                    continue;
                                }

                                device.updateTime = currentStat[0];
                            } else {
                                device.updateTime = device.updateTime + j
                                // Let's stop here if we are setting point in the future
                                if (device.updateTime > Math.floor(Date.now() / 1000)) {
                                    break;
                                }
                            }

                            if (j === 0) {
                                // First iteration we are just updating timestamp
                                continue
                            }

                            // Remove oldest data point
                            const oldestPoint = device.points.shift();

                            // Check if we will need to recalculate graph peak
                            if (oldestPoint.rx >= this.graph.infos.peak.rx || oldestPoint.tx >= this.graph.infos.peak.tx) {
                                changeGlobalPeak = true
                                changeDevicePeak = true
                                device.peak.rx = 1;
                                device.peak.tx = 1;
                            } else if (oldestPoint.rx >= device.peak.rx || oldestPoint.tx >= device.peak.tx) {
                                changeDevicePeak = true
                                device.peak.rx = 1;
                                device.peak.tx = 1;
                            }

                            let rx = 0,
                                tx = 0;

                            // Normalize difference against time interval
                            if (typeof currentStat !== 'undefined') {
                                const previousStat = deviceStats[j - 1],
                                    delta = currentStat[0] - previousStat[0];

                                // Get rx/tx diff
                                if (delta) {
                                    rx = (currentStat[1] - previousStat[1]) / delta;
                                    tx = (currentStat[3] - previousStat[3]) / delta;
                                }
                            }

                            // Calculate exponentially moving average
                            const lastPoint = device.points[device.points.length - 1],
                                newPoint = {
                                    rx: lastPoint.rx + (rx - lastPoint.rx) / this.graph.smoother,
                                    tx: lastPoint.tx + (tx - lastPoint.tx) / this.graph.smoother
                                };

                            device.points.push(newPoint);

                            // Change peak value if needed
                            device.peak.rx = newPoint.rx > device.peak.rx ? newPoint.rx : device.peak.rx;
                            device.peak.tx = newPoint.tx > device.peak.tx ? newPoint.tx : device.peak.tx;

                            if (newPoint.rx > this.graph.infos.peak.rx || newPoint.tx > this.graph.infos.peak.tx) {
                                changeGlobalPeak = true
                            }
                        }

                        // Plot data
                        // If we are not looking for a new peak and we need to redraw everything
                        // We can skip this
                        let rxCurve = '0,' + this.graph.height,
                            txCurve = '0,' + this.graph.height,
                            pos = 0;

                        for (const p of device.points) {
                            // We need to find the new current peak
                            if (changeDevicePeak) {
                                device.peak.rx = p.rx > device.peak.rx ? p.rx : device.peak.rx;
                                device.peak.tx = p.tx > device.peak.tx ? p.tx : device.peak.tx;
                            } else if (changeGlobalPeak) {
                                // We don't need to be here
                                // We are not looking for a new peak and we need to redraw everything
                                break;
                            }

                            // Redraw
                            // If hscale is about to change, we skip it as we need to redraw everything
                            if (!changeGlobalPeak) {
                                let x = pos * this.graph.step,
                                    yRX = otbgraph.computeHpoint(this.graph.height, this.graph.infos.hscale.rx, p.rx),
                                    yTX = otbgraph.computeHpoint(this.graph.height, this.graph.infos.hscale.tx, p.tx);

                                rxCurve += ' ' + x + ',' + yRX;
                                txCurve += ' ' + x + ',' + yTX;

                                // Thats the last point
                                if (pos === device.points.length - 1) {
                                    rxCurve += ' ' + this.graph.width + ',' + yRX + ' ' + this.graph.width + ',' + this.graph.height;
                                    txCurve += ' ' + this.graph.width + ',' + yTX + ' ' + this.graph.width + ',' + this.graph.height;

                                    // Save redraw
                                    this.graph.svgRX.getElementById('rx_' + device.name).setAttribute('points', rxCurve);
                                    this.graph.svgTX.getElementById('tx_' + device.name).setAttribute('points', txCurve);
                                }
                            }

                            pos++;
                        }
                    }

                    if (changeGlobalPeak) {
                        this.graph.infos.peak.rx = 1;
                        this.graph.infos.peak.tx = 1;

                        for (const device of this.graph.devices) {
                            this.graph.infos.peak.rx = device.peak.rx > this.graph.infos.peak.rx ? device.peak.rx : this.graph.infos.peak.rx;
                            this.graph.infos.peak.tx = device.peak.tx > this.graph.infos.peak.tx ? device.peak.tx : this.graph.infos.peak.tx;
                        }

                        this.graph.infos.hscale = {
                            rx: otbgraph.computeHscale(this.graph.height, this.graph.infos.peak.rx),
                            tx: otbgraph.computeHscale(this.graph.height, this.graph.infos.peak.tx),
                        }

                        // We got the new scale we need to redraw everything
                        for (const device of this.graph.devices) {
                            let rxCurve = '0,' + this.graph.height,
                                txCurve = '0,' + this.graph.height,
                                pos = 0;

                            for (const p of device.points) {
                                let x = pos * this.graph.step,
                                    yRX = otbgraph.computeHpoint(this.graph.height, this.graph.infos.hscale.rx, p.rx),
                                    yTX = otbgraph.computeHpoint(this.graph.height, this.graph.infos.hscale.tx, p.tx);

                                rxCurve += ' ' + x + ',' + yRX;
                                txCurve += ' ' + x + ',' + yTX;

                                // Thats the last point
                                if (pos === device.points.length - 1) {
                                    rxCurve += ' ' + this.graph.width + ',' + yRX + ' ' + this.graph.width + ',' + this.graph.height;
                                    txCurve += ' ' + this.graph.width + ',' + yTX + ' ' + this.graph.width + ',' + this.graph.height;

                                    // Save redraw
                                    this.graph.svgRX.getElementById('rx_' + device.name).setAttribute('points', rxCurve);
                                    this.graph.svgTX.getElementById('tx_' + device.name).setAttribute('points', txCurve);
                                }
                                pos++;
                            }
                        }

                        // We change labels
                        this.graph.infos.hlabels = {
                            rx: {
                                l25: otbgraph.computeHlabel(this.graph.height, this.graph.infos.hscale.rx, 0.25),
                                l50: otbgraph.computeHlabel(this.graph.height, this.graph.infos.hscale.rx, 0.50),
                                l75: otbgraph.computeHlabel(this.graph.height, this.graph.infos.hscale.rx, 0.75),
                            },
                            tx: {
                                l25: otbgraph.computeHlabel(this.graph.height, this.graph.infos.hscale.tx, 0.25),
                                l50: otbgraph.computeHlabel(this.graph.height, this.graph.infos.hscale.tx, 0.50),
                                l75: otbgraph.computeHlabel(this.graph.height, this.graph.infos.hscale.tx, 0.75),
                            }
                        }
                    }

                    if (typeof (this.graph.legend) === 'function') {
                        this.graph.legend(this.graph.svgRX, this.graph.svgTX, this.graph.infos);
                    }
                }, this));
        }, this), this.graph.infos.interval);
    },

    render: function (data) {
        // Check if this render is executed for the first time
        if (!this.pollIsActive) {
            let network = data[0],
                svgRX = otbsvg.createBackground(),
                svgTX = otbsvg.createBackground();

            var body = E('fieldset', { class: 'cbi-section' }, [
                E('div', { id: 'overthebox_graph' }, [
                    E('table', { 'width': "100%" }, [
                        E('tr', [
                            E('td', { 'style': 'border-style: none; width: 50%; padding-bottom: 0' }, E('strong', _('Download:'))),
                            E('td', { 'style': 'border-style: none; width: 50%; padding-bottom: 0' }, E('strong', _('Upload:'))),
                        ]),
                        E('tr', [
                            E('td', { 'style': 'border-style: none;' }, [
                                E('div', {
                                    'id': 'svgRX',
                                    'class': 'svg-graph',
                                    'style': 'width:100%; height:300px;'
                                }, svgRX),
                                E('div', { 'style': 'text-align:right' }, E('small', { 'id': 'dnscale' }, '-'))
                            ]),
                            E('td', { 'style': 'border-style: none;' }, [
                                E('div', {
                                    'id': 'svgTX',
                                    'class': 'svg-graph',
                                    'style': 'width:100%; height:300px;',
                                }, svgTX),
                                E('div', { 'style': 'text-align:right' }, E('small', { 'id': 'upscale' }, '-'))
                            ])
                        ])
                    ])
                ])
            ]);


            this.createGraph(svgRX, svgTX, network, function (svgRX, svgTX, infos) {
                svgRX.getElementById('label_25').firstChild.data = rate(infos.hlabels.rx.l25).join('');
                svgRX.getElementById('label_50').firstChild.data = rate(infos.hlabels.rx.l50).join('');
                svgRX.getElementById('label_75').firstChild.data = rate(infos.hlabels.rx.l75).join('');

                svgRX.parentNode.parentNode.querySelector('#dnscale').firstChild.data = _('(%d minute window, %d second interval)').format(infos.timeframe, infos.interval);

                svgTX.getElementById('label_25').firstChild.data = rate(infos.hlabels.tx.l25).join('');
                svgTX.getElementById('label_50').firstChild.data = rate(infos.hlabels.tx.l50).join('');
                svgTX.getElementById('label_75').firstChild.data = rate(infos.hlabels.tx.l75).join('');

                svgTX.parentNode.parentNode.querySelector('#upscale').firstChild.data = _('(%d minute window, %d second interval)').format(infos.timeframe, infos.interval);
            });

            this.pollData();
            this.pollIsActive = 1
            return body;
        }
    }
});
