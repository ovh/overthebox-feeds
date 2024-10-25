"use strict";
"require view";
"require fs";
'require ui';

let speedtestResults = null;

return view.extend({
  title: _("Speedtest"),

  render: function () {

    return E('div', { 'class': 'cbi-section', 'id': 'speedtest' }, [
      E('h1', this.title),
      E('div', { 'class': 'cbi-section' }, [
        E('button', {
          'class': 'btn cbi-button-action',
          'id': 'btnLaunch',
          'click': ui.createHandlerFn(this, function(ev) {
            // Hide button to avoid another launch
            const button = document.getElementById('btnLaunch');
            button.style.display = 'none';

            const parentNode = document.getElementById('speedtest');

            // Check if speedtestResults is not already displayed to remove it
            const isSpeedtestResults = document.getElementById('speedtestResults');
            if (isSpeedtestResults) {
              parentNode.removeChild(isSpeedtestResults);
            }

            // Show loading component
            const loading = document.getElementById('loading');
            loading.style.display = 'block';

            // Launch speedtest
            L.resolveDefault(fs.exec_direct("/bin/otb-action-speedtest", ["-j"], "json"), '').then(function(data) {
              const ports = Object.keys(data);

              let container = [];

              for (let i = 0; i < ports.length; i++) {
                const port = ports[i];
                const element = data[port][0];

                const ifacebox = E('div', { 'class': 'ifacebox', 'style': 'margin-bottom:10px' }, [
                  E('div', { 'class': 'ifacebox-head center' }, E('strong', port)),
                  E('div', { 'class': 'ifacebox-body' }, [
                    E('div', { 'class': 'cbi-section' }, [
                      E('table', { 'class': 'table', 'style': 'width:100%;table-layout:fixed'}, [
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Download:') ])),
                          E('td', { 'class': 'td' }, '%f %s'.format(element.download, _('Mbits/s'))),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Upload:') ])),
                          E('td', { 'class': 'td' }, '%f %s'.format(element.upload, _('Mbits/s'))),
                        ]),
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Bytes sent:') ])),
                          E('td', { 'class': 'td' }, '%d'.format(element.bytes_sent)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Bytes received:') ])),
                          E('td', { 'class': 'td' }, '%d'.format(element.bytes_received)),
                        ]),
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Ping:') ])),
                          E('td', { 'class': 'td' }, '%f'.format(element.ping)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Jitter:') ])),
                          E('td', { 'class': 'td' }, '%f'.format(element.jitter)),
                        ]),
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Timestamp:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.timestamp)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Share:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.share)),
                        ]),
                      ])
                    ]),
                    E('br'),
                    E('div', { 'class': 'cbi-section' }, [
                      E('h3', { 'class': 'left' }, _('Server')),
                      E('table', { 'class': 'table', 'style': 'width:100%;table-layout:fixed' }, [
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Name:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.server.name)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('URL:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.server.url)),
                        ]),
                      ])
                    ]),
                    E('br'),
                    E('div', { 'class': 'cbi-section' }, [
                      E('h3', { 'class': 'left' }, _('Client')),
                      E('table', { 'class': 'table', 'style': 'width:100%;table-layout:fixed' }, [
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('IP:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.ip)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Hostname:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.hostname)),
                        ]),
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('City:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.city)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Postal:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.postal)),
                        ]),
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Region:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.region)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Country:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.country)),
                        ]),
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Localization:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.loc)),

                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Timezone:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.timezone)),
                        ]),
                        E('tr', { 'class': 'tr' }, [
                          E('td', { 'class': 'td left', 'width': '25%' }, E('strong', {}, [ _('Organization:') ])),
                          E('td', { 'class': 'td' }, '%s'.format(element.client.org)),
                        ]),
                      ])
                    ])
                  ])
                ]);

                container.push(ifacebox);
              }

              // Hide loading component
              loading.style.display = 'none';

              // Add speedtest results
              const speedtestResults = E('div', { 'class': 'cbi-section', 'id': 'speedtestResults' }, container);
              parentNode.appendChild(speedtestResults);

              // Show launch button
              button.style.display = 'block';
            });
          }),
        }, _('Launch speedtest'))
      ]),
      E('br'),
      E('em', { id: 'loading', 'class': 'spinning', 'style':'display:none' }, _('The speedtest is running, please wait...')),
    ]);
  },

  handleSaveApply: null,
  handleSave: null,
  handleReset: null,
});
