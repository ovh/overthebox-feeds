'use strict';
'require view';
'require uci';
'require ui';
'require fs';
'require poll';
'require tools.overthebox.ovh as ovhapi';
'require tools.overthebox.ui as otbui';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/custom.css')
}));

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/status.css')
}));

return view.extend({
    title: _('Register'),

    load: function () {
        let auth = ovhapi.authentication()
            .then(() => {
                return {
                    logged: 'true',
                }
            })
            .catch(() => {
                return {
                    logged: 'false'
                }
            });

        return Promise.all([
            uci.load('overthebox'),
            auth
        ]);
    },

    render: function (data) {
        let box = E('div', { 'class': 'cbi-section' }, [E('h1', this.title)]),
            bar = [
                { id: 'login', name: _('Login'), state: '' },
                { id: 'register', name: _('Register'), state: '' },
                { id: 'activate', name: _('Activate'), state: '' },
                { id: 'ready', name: _('Ready'), state: '' },
            ];

        // We check if a service exist in config
        const serviceID = uci.get('overthebox', 'me', 'service');

        // There is no service associated with this device
        // We need to associate it with OVHcloud API
        if (!serviceID) {
            // We are logged in on OVHcloud API
            // We need to select a service to associate this device with
            if (data[1].logged === 'true') {
                bar[0].state = 'ok';
                bar[1].state = 'nok';
                box.appendChild(otbui.createStatusBar(bar));
                box.appendChild(this.renderAssociate(data[1].values));
                return box;
            }

            bar[0].state = 'nok';
            box.appendChild(otbui.createStatusBar(bar));
            box.appendChild(this.renderLogin());
            return box;
        }
        bar[0].state = 'ok';
        bar[1].state = 'ok';

        // A service has already been associated, we don't need to interact with OVHcloud API
        // We check if service is activated
        const needsActivation = uci.get('overthebox', 'me', 'needs_activation');

        // Service is deactivated, user need to confirm activation with OTB ovhapis
        if (needsActivation === 'true') {
            bar[2].state = 'nok';
            box.appendChild(otbui.createStatusBar(bar));
            box.appendChild(this.renderActivate(serviceID));
            return box;
        }

        bar[2].state = 'ok';
        bar[3].state = 'ok';

        // Service found and activated, user can just enjoy his service
        const deviceID = uci.get('overthebox', 'me', 'device_id');
        box.appendChild(otbui.createStatusBar(bar));
        box.appendChild(this.renderEnjoy(serviceID, deviceID));
        return box;
    },

    // No service found, user need to log in to OVHcloud API to retrieve his available services
    renderLogin: function () {
        let loginBtn = E('button', { 'class': 'cbi-button cbi-button-add', 'title': 'Login' }, _('Login'));

        loginBtn.onclick = () => {
            ovhapi.connect()
                .then(
                    data => {
                        ovhapi.consumer = data.consumerKey

                        if (!data.validationUrl) {
                            return Promise.reject({
                                'code': '406 Not Acceptable',
                                'type': 'device_error',
                                'message': _('Validation URL is invalid')
                            })
                        } else {
                            const d = new Date();
                            d.setTime(d.getTime() + (24 * 60 * 60 * 1000));
                            let expires = "expires=" + d.toUTCString();
                            document.cookie = 'consumerKey=' + data.consumerKey + ' ;' + expires + ' ;SameSite=Lax;';
                            window.location.href = data.validationUrl;
                        }
                    }
                )
                .catch(
                    err => {
                        otbui.createSimpleModal(
                            _('Failure'),
                            _('Error while connecting to OVHcloud API:\n %s').format(JSON.stringify(err, null, '\t'))
                        );
                    }
                );
        };

        return E('div', [
            E('h2', _('Install easily your OverTheBox Service')),
            E('h3', _('')),
            E('p', _('You need to register this device with your subscription by signing-in to your OVHcloud account')),
            E('p', { 'class': 'cbi-value-description' }, [
                _('You will be redirected to a page named') + ' ',
                E('strong', _('Permission to access your account')),
                E('br'),
                _('Please click on the button') + ' ',
                E('strong', _('Authorize Access')),
                ' ' + _('to log in')
            ]),
            loginBtn
        ]);
    },

    // No service found, user is logged in and need to select a service to associate his device with
    renderAssociate: function () {
        let box = E('div', [E('h2', _('Service Activation'))]);

        otbui.createBlockingModal(
            _('Loading'),
            _('Retrieving services list from OVHcloud API...')
        );

        this.loadServices(box);

        return box
    },

    // Service found, but is deactivated, user need to confirm activation with OTB ovhapis
    renderActivate: function (serviceID) {
        let activateBtn = E('button', { 'class': 'cbi-button cbi-button-add', 'title': 'Activate' }, _('Activate'));

        activateBtn.onclick = () => {
            fs.exec('/bin/otb-confirm-service', null, null)
                .then(
                    () => {
                        uci.unload('overthebox');
                        otbui.createSimpleModal(
                            _('Success'),
                            _('Service activation has been successful')
                        );
                    }
                )
                .catch(
                    err => otbui.createSimpleModal(
                        _('Failure'),
                        _('Fail to activate service: %s').format(err.message)
                    )
                );
        };

        return E('div', [
            E('h2', _('Service Activation')),
            E('h3', _('Activation')),
            E('p', _('Your device has been correctly registered, you need to activate your service')),
            E('p', _('serviceID: %s').format(serviceID)),
            activateBtn
        ]);
    },

    // Service registration is complete
    renderEnjoy: function (serviceID, deviceID) {
        let fields = [
            _('serviceID'), serviceID,
            _('deviceID'), deviceID,
        ],
            table = otbui.createTabularElem(fields);

        return E('div', [
            E('h2', 'OverTheBox Status'),
            table
        ]);
    },

    loadServices: async function (box) {
        // Retrieve services list
        let call = await ovhapi.services()
            .then(
                data => {
                    if (data.length == 0) {
                        otbui.createSimpleModal(
                            _('Failure'),
                            _('This account does not have any OverTheBox services')
                        );
                        return { error: true, values: data }
                    }

                    ui.hideModal()
                    return { error: false, values: data }
                }
            )
            .catch(
                err => {
                    otbui.createSimpleModal(
                        _('Failure'),
                        _('Error while retrieving service names on OVHcloud API:\n %s').format(err)
                    );
                    return { error: true, values: err }
                }
            );

        if (call.error) {
            return box
        }

        let data = call.values;

        // Create association button
        let associateBtn = E('button', {
            'class': 'cbi-button cbi-button-add',
            'title': 'Associate',
            'click': () => {
                let select = document.getElementById('serviceChoice'),
                    serviceID = select.value,
                    deviceID = uci.get('overthebox', 'me', 'device_id');

                if (!serviceID) {
                    otbui.createSimpleModal(
                        _('Failure'),
                        _('Invalid ServiceID'),
                    );
                    return
                } else if (!deviceID) {
                    otbui.createSimpleModal(
                        _('Failure'),
                        _('Invalid deviceID'),
                    );
                    return
                }

                if (!confirm(_('This will override previous device association, are you sure?'))) {
                    return;
                }

                ui.showModal(_('Association…'), [
                    E('p', { 'class': 'spinning' }, _('Performing device association...'))
                ]);

                ovhapi.linkDevice(serviceID, deviceID)
                    .then(
                        data => {
                            window.setTimeout(function () {
                                ui.showModal(_('Association…'), [
                                    E('p', { 'class': 'spinning alert-message warning' },
                                        _('Still waiting for associatoin, please reload the page...'))
                                ]);
                            }, 150000);

                            window.setTimeout(
                                L.bind(function () {
                                    poll.add(L.bind(function () {
                                        uci.unload('overthebox');

                                        return Promise.all([uci.load('overthebox')])
                                        .then(() => {
                                            const serviceID = uci.get('overthebox', 'me', 'service');

                                            if (serviceID) {
                                                poll.stop();
                                                location.reload();
                                            }
                                        });
                                    }, this));
                                }, this), 5000);
                        }
                    )
                    .catch(
                        err => otbui.createSimpleModal(
                            _('Failure'),
                            _('Fail to associate service on OVHcloud API:\n %s').format(JSON.stringify(err, null, '\t'))
                        )
                    );
            }
        }, _('Associate'));

        // Create Select Element
        let services = {},
            serviceInfos = E('div', { 'id': 'serviceInfos' }, [E('p', {}, '')]);

        let select = E('select', { 'class': 'cbi-input-select', 'style': 'width:32rem' }, [
            E('option', { 'value': 'placeHolder' }, _('Select a service'))
        ]);

        select.id = 'serviceChoice';

        const handleInfos = this.loadServiceInfos();

        select.addEventListener('change', function (ev) {
            if (this.value === 'placeHolder') {
                associateBtn.style.display = 'none';
                serviceInfos.firstChild.replaceWith(E('p', ''));
                return
            }

            if (!services[this.value]) {
                associateBtn.style.display = 'none';
                serviceInfos.style.display = 'block';
                serviceInfos.firstChild.replaceWith(E('p', _('No informations found for this service')));
                return
            }

            // We need to load data
            if (services[this.value].state === 'pending') {
                let id = this.value

                // Load
                async function load() {
                    const infos = await handleInfos.get(id).then(
                        data => {
                            return data;
                        }
                    );

                    const details = infos[0],
                        device = infos[1];

                    if (details.error || device.error) {
                        services[id].state = 'error';
                        return
                    }

                    let option = document.getElementById(id);
                    option.textContent = details.values.customerDescription;

                    services[id].infos = handleInfos.format(details, device)
                    services[id].state = 'ok';
                    ui.hideModal()
                }

                load().then(
                    () => {
                        if (services[id].state === 'error') {
                            associateBtn.style.display = 'none';
                            serviceInfos.style.display = 'block';
                            serviceInfos.firstChild.replaceWith(E('p', _('Fail to retrieve informations for this service')));
                            return
                        }

                        associateBtn.style.display = 'inline';
                        serviceInfos.firstChild.replaceWith(otbui.createTabularElem(services[id].infos));
                        serviceInfos.style.block = 'block';
                    }
                );

                otbui.createBlockingModal(
                    _('Loading'),
                    _('Retrieving services informations from OVHcloud API...')
                );
            } else {
                if (services[this.value].state === 'error') {
                    associateBtn.style.display = 'none';
                    serviceInfos.style.display = 'block';
                    serviceInfos.firstChild.replaceWith(E('p', _('Fail to retrieve informations for this service')));
                    return
                }

                associateBtn.style.display = 'inline';
                serviceInfos.firstChild.replaceWith(otbui.createTabularElem(services[this.value].infos));
                serviceInfos.style.block = 'block';
            }
        });

        let count = data.length;

        // Preload only if we have less than 25 services
        if (count > 25) {
            ui.addNotification(null, E('p', [
                _('Fail to preload services informations, %d services found which is over preloading limit').format(data.length)
            ]), 'warning');
        }

        for (let id of data) {
            services[id] = {
                'id': id,
                'state': 'pending',
            };

            let option = E('option', { 'id': id, 'value': id }, id)
            select.appendChild(option);

            if (count > 25) {
                continue
            }

            // Preload
            async function preload() {
                const infos = await handleInfos.get(id).then(
                    data => {
                        return data;
                    }
                );

                const details = infos[0],
                    device = infos[1];

                if (details.error || device.error) {
                    services[id].state = 'error';
                    return
                }

                option.textContent = details.values.customerDescription;

                services[id].infos = handleInfos.format(details, device)
                services[id].state = 'ok';
                count--;

                otbui.createBlockingModal(
                    _('Loading'),
                    _('(%d/%d) Retrieving services informations from OVHcloud API...').format(count, data.length)
                );

                if (count === 0) {
                    ui.hideModal()
                }
            }

            otbui.createBlockingModal(
                _('Loading'),
                _('(%d/%d) Retrieving services informations from OVHcloud API...').format(count, data.length)
            );

            preload();
        }

        box.appendChild(E('p', _('Select the service you wish to associate with this device')))
        box.appendChild(select);
        box.appendChild(associateBtn);
        box.appendChild(serviceInfos);
    },

    loadServiceInfos: function () {
        return {
            get: async function (id) {
                return Promise.all([
                    ovhapi.service(id)
                        .then(
                            data => {
                                if (data.length == 0) {
                                    return { error: true, values: data }
                                }

                                return { error: false, values: data }
                            }
                        )
                        .catch(
                            err => {
                                return { error: true, values: err }
                            }
                        ),
                    ovhapi.device(id)
                        .then(
                            data => {
                                if (data.length == 0) {
                                    return { error: true, values: data }
                                }

                                let diff = 1000000;

                                if (data.lastSeen) {
                                    const date = new Date(data.lastSeen),
                                        now = new Date().getTime();

                                    data.lastSeen = date.toString();
                                    diff = now - date
                                }

                                // Last 15 mn
                                data.state = diff < 900000 ? '\u2705 ' + _('Connected') : '\u274C ' + _('Disconnected')

                                return { error: false, values: data }
                            }
                        )
                        .catch(
                            err => {
                                return { error: true, values: err }
                            }
                        ),
                ]);
            },
            format: function (details, device) {
                return [
                    _('Service description'), details.values.customerDescription,
                    _('ServiceID'), details.values.serviceName,
                    _('Service status'), details.values.status,
                    _('DeviceID'), device.values.deviceId,
                    // Last 15 mn
                    _('Device status'), device.values.state,
                    _('Device last connection'), device.values.lastSeen,
                    _('Device last IP'), device.values.publicIp,
                    _('Device feeds version'), device.values.version,
                    _('Device system version'), device.values.systemVersion,
                ]
            }
        }
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
