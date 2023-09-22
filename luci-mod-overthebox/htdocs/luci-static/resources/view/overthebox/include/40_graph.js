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
'require tools.overthebox.graph as graph';
'require tools.overthebox.ui as otbui';

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

var graphPolls = [],
	pollInterval = 1, pollIsActive = 0;

Math.log2 = Math.log2 || function (x) { return Math.log(x) * Math.LOG2E; };

function rate(n, br) {
	n = (n || 0).toFixed(2);
	return ['%1024.2mbit/s'.format(n * 8), br ? E('br') : ' ', '(%1024.2mB/s)'.format(n)]
}

return baseclass.extend({
	title: _('Realtime Traffic'),

	load: function () {
		return Promise.all([
			network.getNetworks(),
			uci.load('network'),
			this.loadSVG(L.resource('svg/bandwidth.svg'))
		]);
	},

	createGraph: function (svgs, network, cb) {
		var width = 500 - 2;
		var height = 300 - 2;
		var step = 5;
		var data_wanted = Math.floor(width / step);
		var Gdn = svgs[0],
			Gup = svgs[1];
		var ifnames = [];
		var info = {
			line_peak: [],
		};
		var dndata = {};
		var updata = {};
		var timestamp = [];

		var interfaces = uci.sections('network', 'interface');

		// Search for interfaces which use multipath
		for (var j = 0; j < interfaces.length; j++) {
			if (interfaces[j].multipath == "on" ||
				interfaces[j].multipath == "master" ||
				interfaces[j].multipath == "backup" ||
				interfaces[j].multipath == "handover") {
				var itf = interfaces[j].device;
				ifnames.push(itf)
				var color = graph.stringToColour(itf);

				// Create a new polygon to draw the bandwith
				var dnline = otbui.createPolyLineElem('rx_' + itf, color, 0.6);
				Gdn.appendChild(dnline);

				// Prefill datasets
				dndata[itf] = [];
				for (var i = 0; i < data_wanted; i++) {
					dndata[itf][i] = 0;
				}

				var upline = otbui.createPolyLineElem('tx_' + itf, color, 0.6);
				Gup.appendChild(upline);

				// Prefill datasets
				updata[itf] = [];
				for (var i = 0; i < data_wanted; i++) {
					updata[itf][i] = 0;
				}
				timestamp[itf] = 0;
			}
		}

		// Plot horizontal time interval lines
		for (var i = width % (step * 60); i < width; i += step * 60) {
			// Create Line element for download
			var linedn = otbui.createLineElem(i, 0, i, '100%');

			// Create Text element for download
			var textdn = otbui.createTextElem(i + 5, 15);
			textdn.appendChild(document.createTextNode(Math.round((width - i) / step / 60) + 'm'));

			// Append download line and text to download plot
			Gdn.appendChild(linedn);
			Gdn.appendChild(textdn);

			// Create Line element for upload
			var lineup = otbui.createLineElem(i, 0, i, '100%');

			// Create Text element for upload
			var textup = otbui.createTextElem(i + 5, 15);
			textup.appendChild(document.createTextNode(Math.round((width - i) / step / 60) + 'm'));

			// Append upload line and text to upload plot
			Gup.appendChild(lineup);
			Gup.appendChild(textup);
		}

		info.interval = pollInterval;
		info.timeframe = data_wanted / 60;

		graphPolls.push({
			ifnames: ifnames,
			svgs: svgs,
			cb: cb,
			info: info,
			width: width,
			height: height,
			step: step,
			dnvalues: dndata,
			upvalues: updata,
			timestamp: timestamp,
		});
	},

	pollData: function () {
		poll.add(L.bind(function () {
			var tasks = [];
			for (var i = 0; i < graphPolls.length; i++) {
				var ctx = graphPolls[i];
				ctx.ifnames.forEach((ifname) => {
					tasks.push(L.resolveDefault(callLuciRealtimeStats('interface', ifname), []));
					tasks.push(L.resolveDefault(callLuciDeviceStatus(ifname, {})));
				})
			}
			return Promise.all(tasks).then(L.bind(function (datasets) {
				for (var gi = 0; gi < graphPolls.length; gi += ctx.ifnames.length) {

					var ctx = graphPolls[gi],
						data = {
							timestat: {},
							status: {},
						},
						dnvalues = ctx.dnvalues,
						upvalues = ctx.upvalues,
						info = ctx.info;

					var data_scale_dn = 0;
					var data_scale_up = 0;
					var data_wanted = Math.floor(ctx.width / ctx.step);
					var dnsma = {};
					var upsma = {};

					// Store timestat result
					for (var i = 0; i < ctx.ifnames.length; i++) {
						data.timestat[ctx.ifnames[i]] = datasets[2 * i];
						data.status[ctx.ifnames[i]] = datasets[((2 * i) + 1)];
					}
					data.list = datasets[datasets.length - 1];

					info.line_peak['tx'] = NaN;
					info.line_peak['rx'] = NaN;

					ctx.ifnames.forEach((ifname) => {
						// Check if interface is not present, eg 4G key
						if (!data.status[ifname].present) {
							dnvalues[ifname].push(0);
							upvalues[ifname].push(0);
						} else {
							if (!dnsma[ifname]) {
								dnsma[ifname] = graph.simple_moving_averager('down_' + ifname, 15);
							} else if (!upsma[ifname]) {
								upsma[ifname] = graph.simple_moving_averager('up_' + ifname, 15);
							}

							for (var j = ctx.timestamp[ifname] ? 0 : 1; j < data.timestat[ifname].length; j++) {
								var last_timestamp = NaN;

								// Skip overlapping entries
								if (data.timestat[ifname][j][0] <= ctx.timestamp[ifname]) {
									continue;
								}

								isNaN(last_timestamp) ? last_timestamp = data.timestat[ifname][j][0] : last_timestamp = Math.max(last_timestamp, data[ifname][j][0]);

								// Normalize difference against time interval
								if (j > 0) {
									var time_delta = data.timestat[ifname][j][0] - data.timestat[ifname][j - 1][0];
									if (time_delta) {
										dnvalues[ifname].push(dnsma[ifname]((data.timestat[ifname][j][1] - data.timestat[ifname][j - 1][1]) / time_delta));
										upvalues[ifname].push(upsma[ifname]((data.timestat[ifname][j][3] - data.timestat[ifname][j - 1][3]) / time_delta));
									}
								}
							}
						}

						// Cut off outdated entries
						dnvalues[ifname] = dnvalues[ifname].slice(dnvalues[ifname].length - data_wanted, dnvalues[ifname].length);
						upvalues[ifname] = upvalues[ifname].slice(upvalues[ifname].length - data_wanted, upvalues[ifname].length);

						// Find peaks
						for (var index = 0; index < dnvalues[ifname].length; index++) {
							info.line_peak['tx'] = isNaN(info.line_peak['tx']) ? upvalues[ifname][index] : Math.max(info.line_peak['tx'], upvalues[ifname][index]);
							info.line_peak['rx'] = isNaN(info.line_peak['rx']) ? dnvalues[ifname][index] : Math.max(info.line_peak['rx'], dnvalues[ifname][index]);
						}

						// Remember current timestamp, calculate horizontal scale
						if (!isNaN(last_timestamp)) {
							ctx.timestamp[ifname] = last_timestamp;
						}
					})

					for (var direction in info.line_peak) {
						var size = Math.floor(Math.log2(info.line_peak[direction])),
							div = Math.pow(2, size - (size % 10)),
							mult = info.line_peak[direction] / div,
							mult = (mult < 5) ? 2 : ((mult < 50) ? 10 : ((mult < 500) ? 100 : 1000));

						info.line_peak[direction] = info.line_peak[direction] + (mult * div) - (info.line_peak[direction] % (mult * div));

						direction == 'rx' ? data_scale_dn = ctx.height / info.line_peak[direction] : data_scale_up = ctx.height / info.line_peak[direction];
					}

					// Plot data
					ctx.ifnames.forEach((ifname) => {
						// Plot download data
						var dnel = ctx.svgs[0].getElementById('rx_' + ifname),
							dnpt = '0,' + ctx.height,
							dny = 0;

						if (dnel) {
							for (var i = 0; i < dnvalues[ifname].length; i++) {
								var x = i * ctx.step;

								dny = ctx.height - Math.floor(dnvalues[ifname][i] * data_scale_dn);
								//y -= Math.floor(y % (1 / data_scale));
								dny = isNaN(dny) ? ctx.height : dny;
								dnpt += ' ' + x + ',' + dny;
							}

							dnpt += ' ' + ctx.width + ',' + dny + ' ' + ctx.width + ',' + ctx.height;
							dnel.setAttribute('points', dnpt);
						}

						// Plot upload data
						var upel = ctx.svgs[1].getElementById('tx_' + ifname),
							uppt = '0,' + ctx.height,
							upy = 0;
						if (upel) {
							for (var i = 0; i < upvalues[ifname].length; i++) {
								var x = i * ctx.step;

								upy = ctx.height - Math.floor(upvalues[ifname][i] * data_scale_up);
								//y -= Math.floor(y % (1 / data_scale));
								upy = isNaN(upy) ? ctx.height : upy;
								uppt += ' ' + x + ',' + upy;
							}

							uppt += ' ' + ctx.width + ',' + upy + ' ' + ctx.width + ',' + ctx.height;
							upel.setAttribute('points', uppt);
						}
					})

					/* TO DO : now draw top line */

					info.dn_label_25 = 0.25 * info.line_peak['rx'];
					info.dn_label_50 = 0.50 * info.line_peak['rx'];
					info.dn_label_75 = 0.75 * info.line_peak['rx'];

					info.up_label_25 = 0.25 * info.line_peak['tx'];
					info.up_label_50 = 0.50 * info.line_peak['tx'];
					info.up_label_75 = 0.75 * info.line_peak['tx'];

					if (typeof (ctx.cb) == 'function') {
						ctx.cb(ctx.svgs, info);
					}
				}
			}, this));
		}, this), pollInterval);
	},

	loadSVG: function (src) {
		return request.get(src).then(function (response) {
			if (!response.ok) {
				throw new Error(response.statusText);
			}

			return E(response.text());
		});
	},

	render: function (data) {
		// Check if this render is executed for the first time
		if (!pollIsActive) {
			var network = data[1];
			var svg = data[2];
			var csvgs = [];
			csvgs.push(svg.cloneNode(true));
			csvgs.push(svg.cloneNode(true));

			var body = E('fieldset', { class: 'cbi-section' }, [
				E('div', { id: 'overthebox_graph' }, [
					E('table', { 'width': "100%" }, [
						E('tr', [
							E('td', { 'style': 'border-style: none; width: 500px; padding-bottom: 0' }, E('strong', _('Download:'))),
							E('td', { 'style': 'border-style: none; width: 500px; padding-bottom: 0' }, E('strong', _('Upload:'))),
						]),
						E('tr', [
							E('td', { 'style': 'border-style: none;' }, [
								E('div', {
									'id': 'dnsvg',
									'class': 'svg-graph',
									'style': 'width:500px; height:300px;'
								}, csvgs[0]),
								E('div', { 'style': 'text-align:right' }, E('small', { 'id': 'dnscale' }, '-'))
							]),
							E('td', { 'style': 'border-style: none;' }, [
								E('div', {
									'id': 'upsvg',
									'class': 'svg-graph',
									'style': 'width:500px; height:300px;',
								}, csvgs[1]),
								E('div', { 'style': 'text-align:right' }, E('small', { 'id': 'upscale' }, '-'))
							])
						])
					])
				])
			]);

			function createGraphCB(svgs, info) {
				var dnG = svgs[0], upG = svgs[1],
					dntab = dnG.parentNode.parentNode,
					uptab = upG.parentNode.parentNode;

				dnG.getElementById('label_25').firstChild.data = rate(info.dn_label_25).join('');
				dnG.getElementById('label_50').firstChild.data = rate(info.dn_label_50).join('');
				dnG.getElementById('label_75').firstChild.data = rate(info.dn_label_75).join('');

				dntab.querySelector('#dnscale').firstChild.data = _('(%d minute window, %d second interval)').format(info.timeframe, info.interval);

				upG.getElementById('label_25').firstChild.data = rate(info.up_label_25).join('');
				upG.getElementById('label_50').firstChild.data = rate(info.up_label_50).join('');
				upG.getElementById('label_75').firstChild.data = rate(info.up_label_75).join('');

				uptab.querySelector('#upscale').firstChild.data = _('(%d minute window, %d second interval)').format(info.timeframe, info.interval);
			}

			this.createGraph(csvgs, network, createGraphCB);
			this.pollData();
			pollIsActive = 1
			return body;
		}
	}
});
