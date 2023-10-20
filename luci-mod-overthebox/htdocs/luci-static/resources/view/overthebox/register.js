'use strict';
'require view';
'require uci';
'require ui';
'require fs';
'require tools.overthebox.ovh as ovhapi';
'require tools.overthebox.ui as otbui';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/custom.css')
}));

return view.extend({
    title: _('Register'),
    step: {},

    load: function () {
        let auth = ovhapi.authentication()
            .then(
                response => {
                    if (!response.ok) {
                        return 'login'
                    }

                    return 'associate'
                }
            )
            .then(
                name => {
                    this.step.name = name;

                    switch (name) {
                        case 'associate':
                            this.step.value = [];
                            return ovhapi.services()
                                .then(response => response.json())
                                .then(
                                    data => {
                                        let call = [];
                                        data.forEach(
                                            id => {
                                                this.step.value.push({ name: id, details: {}, device: {} });

                                                let serviceDetails = ovhapi.service(id)
                                                    .then(response => response.json())
                                                    .then(
                                                        data => {
                                                            let service = this.step.value.find(({ name }) => name === data.serviceName);
                                                            service.details = data;
                                                        }
                                                    );

                                                call.push(serviceDetails);

                                                let deviceDetails = ovhapi.device(id)
                                                    .then(response => response.json())
                                                    .then(
                                                        data => {
                                                            let service = this.step.value.find(({ name }) => name === id);
                                                            service.device = data;
                                                        });

                                                call.push(deviceDetails);
                                            }
                                        );
                                        return Promise.all(call)
                                    }
                                );
                        default:
                            return Promise.resolve(null);
                    };
                }
            );

        return Promise.all([
            L.resolveDefault(uci.load('overthebox')),
            auth
        ]);
    },

    render: function (data) {
        let box = E('div', { 'class': 'cbi-section' }, [
            E('h1', this.title)
        ]);

        // We check if a service exist in config
        const serviceID = uci.get('overthebox', 'me', 'service');

        // Service need registration
        // step1 will ask user to login to OVHcloud API
        // step2 will ask user to select a service for association
        // A service has already been associated, we skip first two step
        if (serviceID) {
            // We check if service is activated
            const needsActivation = uci.get('overthebox', 'me', 'needs_activation');

            if (needsActivation === 'true') {
                // User need to activate his service
                this.step = {
                    name: 'activate',
                    value: {
                        serviceID: serviceID
                    }
                };
            } else {
                // All good user can enjoy his service
                const deviceID = uci.get('overthebox', 'me', 'device_id');
                this.step = {
                    name: 'enjoy',
                    value: {
                        serviceID: serviceID,
                        deviceID: deviceID
                    }
                };
            }
        }

        // We append dynamic content based on registration status
        box.appendChild(this.dispatch())
        return box
    },

    // Dispatch step to the correct renderer
    dispatch: function () {
        switch (this.step.name) {
            case 'login':
                // No service found, user need to log in to OVHcloud API to retrieve his available services
                return this.renderLogin()
            case 'associate':
                // No service found, user is logged in and need to select a service to associate his device with
                return this.renderAssociate()
            case 'activate':
                // Service found, but is deactivated, user need to confirm activation with OTB ovhapis
                return this.renderActivate()
            case 'enjoy':
                // Service found and activated, user can just enjoy his service
                return this.renderEnjoy()
        }
    },

    // No service found, user need to log in to OVHcloud API to retrieve his available services
    renderLogin: function (step) {
        let loginBtn = E('button', { 'class': 'cbi-button cbi-button-add', 'title': 'Login' }, 'Login');

        loginBtn.onclick = () => {
            ovhapi.connect()
                .then(
                    data => {
                        ovhapi.consumer = data.consumerKey

                        if (!data.validationUrl) {
                            err => otbui.createSimpleModal(
                                _('Failure'),
                                _('Error validation URL is invalid')
                            )
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
                    err => otbui.createSimpleModal(
                        _('Failure'),
                        _('Error while connecting to OVHcloud API: ') + err.status + ' ' + err.statusText
                    )
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
        let associateBtn = E('button', { 'class': 'cbi-button cbi-button-add', 'title': 'Associate' }, 'Associate'),
            choices = {
                placeholder: 'Select a service'
            },
            choiceDetails = [];

        this.step.value.forEach(
            s => {
                choices[s.details.serviceName] = s.details.customerDescription;

                let lastSeen = '',
                    diff = 1000000;

                if (s.device.lastSeen) {
                    const date = new Date(s.device.lastSeen),
                        now = new Date().getTime();

                    lastSeen = date.toString();
                    diff = now - date
                }

                let fields = [
                    _('Service ID'), s.details.serviceName,
                    _('Service Status'), s.details.status,
                    _('Device ID'), s.device.deviceId,
                    // Last 15 mn
                    _('Device Status'), diff < 900000 ? '\u2705 ' + _('Connected') : '\u274C ' + _('Disconnected'),
                    _('Device last connection'), lastSeen,
                    _('Device last IP'), s.device.publicIp,
                    _('Device Feeds version'), s.device.version,
                    _('Device System version'), s.device.systemVersion,
                ];

                let table = otbui.createTabularElem(fields);
                table.style.display = 'none';
                table.id = s.details.serviceName;

                choiceDetails.push(table);
            }
        );

        let select = otbui.createSelectElem(choices);
        select.id = 'serviceChoice';

        select.addEventListener('change', function (ev) {
            let tables = document.getElementsByClassName('table');

            for (let i = 0; i < tables.length; i++) {
                tables[i].style.display = tables[i].id === this.value ? 'block' : 'none'
            }
        });

        associateBtn.onclick = () => {
            let select = document.getElementById('serviceChoice');

            if (!confirm(_('This will override previous device association, are you sure?'))) {
                return;
            }

            let serviceID = select.value,
                deviceID = uci.get('overthebox', 'me', 'device_id');

            ovhapi.linkDevice(serviceID, deviceID)
                .then(
                    data => {
                        uci.set('overthebox', 'me', 'service');
                        return uci.save();
                    }
                )
                .then(
                    () => otbui.createSimpleModal(
                        _('Success'),
                        _('Service association has been successful')
                    )
                )
                .catch(
                    err => otbui.createSimpleModal(
                        _('Failure'),
                        _('Error during service association : ') + err.status + ' ' + err.statusText
                    )
                );
        };

        let box = E('div', [
            E('h2', _('Service Activation')),
            E('h3', _('Selection')),
            E('p', _('Select the service you wish to associate with this device')),
            select,
            associateBtn,
        ]);

        choiceDetails.forEach(table => box.appendChild(table));
        return box;
    },

    // Service found, but is deactivated, user need to confirm activation with OTB ovhapis
    renderActivate: function () {
        let activateBtn = E('button', { 'class': 'cbi-button cbi-button-add', 'title': 'Activate' }, 'Activate');

        activateBtn.onclick = () => {
            fs.exec('/bin/otb-confirm-service', null, null)
                .then(
                    () => otbui.createSimpleModal(
                        _('Success'),
                        _('Service activation has been successful')
                    )
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
            activateBtn
        ]);
    },

    // Service registration is complete
    renderEnjoy: function () {
        return E('div', [
            E('h2', 'OverTheBox Status'),
            E('p', 'deviceID: ' + this.step.value.deviceID),
            E('br'),
            E('p', 'serviceID: ' + this.step.value.serviceID),
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});