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

function activate (step) {
    console.log('step '+JSON.stringify(step));
    switch (step.name) {
        case 'step1':
        case 'step2':
            // let services = ovhapi.services()
            //     .then(response => response.json())
            //     .then(data => {
            //         let call = [];
            //         data.forEach(id => {
            //             let details = ovhapi.service(id)
            //             .then(response => response.json())
            //             .then(data => [data.serviceName, data.customerDescription]);
            //             call.push(details);
            //         });
            //         return Promise.all(call)
            //     })
            //     .then((call) => {
            //         let services = {};
            //         call.forEach(s => services[s[0]] = s[1]);
            //         return services;
            //     });

            // services = Promise.all([services]);
            // console.log('services Promise : '+JSON.stringify(services))

            let associateBtn = E('button', {'class': 'cbi-button cbi-button-add', 'title': 'Associate'}, 'Associate');

            let choices = {placeholder: 'Select a service'};
            let choiceDetails = [];
            // let choiceDetails = E('div', [
            //     E('h3', _('Details')),
            // ]);
            // let serviceChoice = E('div', [
            //     E('h3', _('Selection')),
            //     E('p', _('Select the service you wish to associate with this device'))
            // ]);

            step.value.forEach(s => {
                choices[s.details.serviceName] = s.details.customerDescription

                let lastSeen = '';
                let diff = 1000000;
                if (s.device.lastSeen) {
                    let date = new Date(s.device.lastSeen);
                    let now = new Date().getTime();
                    lastSeen = date.toString();
                    diff = now - date
                }

                let fields = [
                    _('Service ID'), s.details.serviceName,
                    _('Service Status'), s.details.status ,
                    _('Device ID'), s.device.deviceId,
                    // Last 15 mn
                    _('Device Status'), diff < 900000 ? '\u2705 '+_('Connected'):'\u274C '+_('Disconnected'),
                    _('Device last connection'), lastSeen,
                    _('Device last IP'), s.device.publicIp,
                    _('Device Feeds version'), s.device.version,
                    _('Device System version'), s.device.systemVersion,
                ];

                let table = otbui.createTabularElem(fields);
                table.style.display = 'none';
                table.id = s.details.serviceName;

                choiceDetails.push(table);
                // serviceChoice.appendChild(E('input', {'type':'radio', 'name':'service-choice', 'id':s.details.serviceName }))
                // serviceChoice.appendChild(E('label', {'for': s.details.serviceName}, s.details.customerDescription+' - '+s.details.serviceName))
                // serviceChoice.appendChild(E('div', {'class': 'otb-service-reveal'}, table))
            }
        )

            // let select = new ui.Select('', choices, {placeholder: 'Select a service'});
            let select = otbui.createSelectElem(choices);
            select.id = 'serviceChoice';

            select.addEventListener('change', function(ev){
                let tables = document.getElementsByClassName('table');
                console.log(tables)
                console.log(this.value)
                for (let i = 0; i < tables.length; i++) {
                    console.log(tables[i].id)
                    if (tables[i].id === this.value) {
                        tables[i].style.display = 'block';
                    } else {
                        tables[i].style.display = 'none';
                    }
                }
            });

            associateBtn.onclick = () => {
                console.log('click');
                let select = document.getElementById('serviceChoice');

                if (!confirm(_('This will override previous device association, are you sure?'))) {
                    return;
                }

                let serviceID = select.value;
                console.log('serviceID: '+serviceID);

                let deviceID = uci.get('overthebox', 'me', 'device_id');
                console.log('deviceID: '+deviceID);

                ovhapi.linkDevice(serviceID, deviceID)
                .then(data => {
                    console.log('registration ok');
                    uci.set('overthebox', 'me', 'service');
                    return uci.save()
                })
                .then(() => ui.addNotification(null, E('p', _('Service association has been successful'), 'success')))
                .catch(err => {
                    console.log('error : '+err);
                    ui.addNotification(null, E('p', 'Error during service association : ' + err.status + ' ' + err.statusText), 'danger');
            });
        };

            let box = E('div', [
                E('h2', _('Service Activation')),
                E('h3', _('Selection')),
                E('p', _('Select the service you wish to associate with this device')),
                select,
                // serviceChoice,
                associateBtn,
            ])
            choiceDetails.forEach(table => box.appendChild(table));
            return box;
        case 'step3':
            let activateBtn = E('button', {'class': 'cbi-button cbi-button-add', 'title': 'Activate'}, 'Activate');

            activateBtn.onclick = () => {
                console.log('click');
                fs.exec('/bin/otb-confirm-service', null, null)
                .then(() => {
                    console.log('Activation success');
                    ui.showModal(_('Success'), [
                        E('span', _('Service activation has been successful'))
                    ]);
                })
                .catch(err => {
                    console.log('Activation Error : '+err);
                    ui.showModal(_('Failure'), [
                        E('span', _('Fail to activate service ')+err)
                    ]);
                })
            };

            return E('div', [
                E('h2', _('Service Activation')),
                E('h3', _('Activation')),
                E('p', _('You device has been correctly registered, you need to activate your service')),
                activateBtn
            ]);
    }
}

return view.extend({
        title: _('Register'),
        step: {},

        load: function () {
            let auth = ovhapi.authentication()
                .then(response => {
                    if (!response.ok) {
                        return 'login'
                    }

                    return 'associate'
                })
                .then(name => {
                    this.step.name = name;
                    switch (name) {
                        case 'associate':
                            this.step.value = [];
                            return ovhapi.services()
                                .then(response => response.json())
                                .then(data => {
                                    let call = [];
                                    data.forEach(id => {
                                        this.step.value.push({ name: id, details: {}, device:{} });

                                        let serviceDetails = ovhapi.service(id)
                                            .then(response => response.json())
                                            .then(data => {
                                                let service = this.step.value.find(({name}) => name === data.serviceName);
                                                service.details = data;
                                            });

                                        call.push(serviceDetails);

                                        let deviceDetails = ovhapi.device(id)
                                            .then(response => response.json())
                                            .then(data => {
                                                let service = this.step.value.find(({name}) => name === id);
                                                service.device = data;
                                            });

                                        call.push(deviceDetails);

                                    });
                                    return Promise.all(call)
                                })
                        default:
                            return Promise.resolve(null);
                    };
                })

                return Promise.all([
                        L.resolveDefault(uci.load('overthebox')),
                        auth
                        // L.resolveDefault(callSystemInfo(), {}),
                        // fs.lines('/etc/otb-version')
                ]);
        },

        render: function (data) {
                console.log(uci.sections('overthebox', 'config', 'me'));
                let box = E('div', { 'class': 'cbi-section' }, [
                        E('h1', this.title)
                ]);

                console.log('data '+JSON.stringify(data))

                // We check if a service exist in config
                const serviceID = uci.get('overthebox', 'me', 'service');

                // Service need registration
                // step1 will ask user to login to OVHcloud API
                // step2 will ask user to select a service for association
                // A service has already been associated, we skip first two step
                if (!serviceID) {
                    // We check if service is activated
                    const needsActivation = uci.get('overthebox', 'me', 'needs_activation');
                    if (needsActivation === 'true') {
                        // User need to activate his service
                        this.step = { name: 'activate', value: { serviceID: serviceID }};
                    } else {
                        // All good user can enjoy his service
                        const deviceID = uci.get('overthebox', 'me', 'device_id');
                        this.step = { name: 'enjoy', value: { serviceID: serviceID, deviceID: deviceID}}
                    }
                }

                // We append dynamic content based on registration status
                box.appendChild(this.dispatch)
                return box


                return box;
        },

        dispatch: function() {
            console.log('step '+JSON.stringify(this.step));

            // Dispatch to the correct renderer
            switch (this.step.name) {
                case 'login':
                    // No service found, user need to logged in to OVHcloud API to retrieve his available services
                    return this.renderLogin()

                case 'associate':
                    // No service found, user is logged in and need to select a service to associate his device with
                    return renderAssociate()

                case 'activate':
                    // Service found, but is deactivated, user need to confirm activation with OTB ovhapis
                    return renderActivate()

                case 'enjoy':
                    // Service found and activated, user can just enjoy his service
                    return renderEnjoy()
            }
        },

        // No service found, user need to logged in to OVHcloud API to retrieve his available services
        renderLogin: function(step) {
            let loginBtn = E('button', {'class': 'cbi-button cbi-button-add', 'title': 'Login'}, 'Login');

            loginBtn.onclick = () => {
                console.log('click');
                ovhapi.connect()
                .then(data => {
                    console.log('data '+JSON.stringify(data));
                    ovhapi.consumer = data.consumerKey
                    console.log('url: '+data.validationUrl)
                    if (!data.validationUrl) {
                        ui.addNotification(null, E('p',  'Error: No validation URL is invalid'));
                    } else {
                        const d = new Date();
                        d.setTime(d.getTime() + (24*60*60*1000));
                        let expires = "expires="+ d.toUTCString();
                        document.cookie ='consumerKey='+data.consumerKey+' ;'+expires+' ;SameSite=Lax;';
                        window.location.href=data.validationUrl;
                    }
                })
                .catch(err => {
                    console.log('error : '+err);
                    ui.addNotification(null, E('p', 'Error while connecting to OVHcloud API : ' + err.status + ' ' + err.statusText) );
            });
        };

        return E('div', [
            E('h2', _('Install easily your OverTheBox Service')),
            E('h3', _('')),
            E('p', _('You need to register this device with your subscription by signing-in to your OVHcloud account')),
            E('p', {'class': 'cbi-value-description'}, [
                _('You will be redirected to a page named') +' ',
                E('strong', _('Permission to access your account')),
                E('br'),
                _('Please click on the button') + ' ',
                E('strong', _('Authorize Access')),
                ' '+_('to login')
            ]),
            loginBtn
        ]);

        },

        // Service registration is complete
        renderEnjoy: function() {
                return E('div', [
                        E('h2', 'OverTheBox Status'),
                        E('p', 'deviceID: '+this.step.value.deviceID),
                        E('br'),
                        E('p', 'serviceID: '+this.step.value.serviceID),
                ])
        },

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
