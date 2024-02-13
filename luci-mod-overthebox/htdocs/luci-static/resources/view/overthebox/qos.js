'use strict';
'require view';
'require form';
'require fs';
'require ui';
'require network';

document.querySelector('head').appendChild(E('link', {
	'rel': 'stylesheet',
	'type': 'text/css',
	'href': L.resource('view/overthebox/css/custom.css')
}));

return view.extend({
	load: function () {
		return Promise.all([
			L.resolveDefault(fs.exec('/usr/bin/awk', ['{ if ((length ($1) != 0) && \
														(index($1, "#") == 0 ) && \
														(index($1, "ipv6") == 0 )) \
														print $1}', '/etc/protocols'], null), {}),
			L.resolveDefault(network.getDevices(), {})
		]);
	},

	cbi_get_knownips: function (netDevs) {
		var knownips = [];
		netDevs.forEach(function (netDev) {
			netDev.getIPAddrs().forEach(function (addr) {
				knownips.push(addr.split('/')[0]);
			});
		})
		return knownips;
	},

	render: function (data) {
		var m, s, o,
			protocols = data[0].stdout.split('\n').sort(),
			ipknownAddresses = this.cbi_get_knownips(data[1]);

		m = new form.Map('dscp', _('QoS Settings'),
			_("Traffic may be classified by many different parameters, such as source address, destination address or traffic type and assigned to a specific traffic class."));

		s = m.section(form.GridSection, 'classify', _('Classification Rules'));
		s.anonymous = true;
		s.addremove = true;
		s.sortable = true;

		o = s.option(form.ListValue, 'direction', _('Direction'));
		o.default = _('upload');
		o.rmempty = false;
		o.value(_('upload'));
		o.value(_('download'));

		o = s.option(form.Value, 'proto', _('Protocol'));
		o.default = _('all');
		o.rmempty = false;
		o.value(_('all'));
		protocols.forEach(function (protocol) {
			if (protocol) {
				o.value(protocol);
			}
		});

		o = s.option(form.Value, 'src_ip', _('Source host'));
		o.rmempty = true;
		o.value('', _('all'));
		ipknownAddresses.forEach(function (ipknownAddress) {
			o.value(ipknownAddress);
		})

		o = s.option(form.Value, 'src_port', _('Source ports'));
		o.rmempty = true;
		o.value('', _(''));
		o.depends('proto', 'tcp');
		o.depends('proto', 'udp');

		o = s.option(form.Value, 'dest_ip', _('Destination host'));
		o.rmempty = true;
		o.value('', _('all'));
		o.depends('direction', 'upload');
		ipknownAddresses.forEach(function (ipknownAddress) {
			o.value(ipknownAddress);
		})

		o = s.option(form.Value, 'dest_port', _('Destination ports'));
		o.rmempty = true;
		o.value('', _('all'));
		o.depends({ proto: "tcp", direction: "upload" });
		o.depends({ proto: "udp", direction: "upload" });

		o = s.option(form.ListValue, "class", _("Class"));
		o.value('cs0', _('Normal'));
		o.value('cs1', _('Low priority'));
		o.value('cs2', _('High priority'));
		o.value('cs4', _('Latency - VoIP'));

		o = s.option(form.Value, 'comment', _('Comment'))

		return m.render()
	},

	handleReset: function (ev) {
		console.log('clicked on reset');
		fs.exec("/bin/otb-dscp-reset").then(function () {
			// Script execution is OK so refresh page
			location.reload();
		}).catch(function (err) {
			ui.showIndicator(null, E('p', err.message));
		});
	}
});
