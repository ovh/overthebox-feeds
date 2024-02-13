'use strict';
'use crypto';

return L.Class.extend({
    key: 'rxaOYP724BG7eG76',
    secret: '4DOAMmAqBVmesDM5Jjp0mRQkBYleqded',
    consumer: '',
    validationURL: '',

    setConsumer: function () {
        const name = 'consumerKey=';

        let ca = document.cookie.split(';');

        for (let i = 0; i < ca.length; i++) {
            let c = ca[i];

            while (c.charAt(0) == ' ') {
                c = c.substring(1);
            }

            if (c.indexOf(name) == 0) {
                this.consumer = c.substring(name.length, c.length);
                return
            }
        }

        this.consumer = '';
    },

    sign: function (method, url, body, timestamp) {
        let s = [
            this.secret,
            this.consumer,
            method,
            url,
            body || '',
            timestamp
        ];

        const enc = new TextEncoder();
        const d = enc.encode(s.join('+'));
        return crypto.subtle.digest('SHA-1', d)
            .then(sha1 => Array.from(new Uint8Array(sha1)))
            // convert bytes to hex string
            .then(array => array.map(b => b.toString(16).padStart(2, "0")).join(""));
    },

    formatError: function (response) {
        if (response.ok) {
            return response.json()
        }

        return Promise.reject(
            response.json()
                .then(data => {
                    return {
                        'code': data.httpCode,
                        'type': data.errorCode,
                        'message': data.message,
                    }
                })
                .catch(error => {
                    return {
                        'code': response.status + response.statusText,
                        'type': 'api_error',
                        'message': _('OVHcloud API call fail'),
                    }
                })
        );
    },

    call: function (method, path, body) {
        const url = "https://eu.api.ovh.com/1.0" + path;
        const timestamp = Math.round(Date.now() / 1000);
        const headers = {
            "Content-Type": "application/json",
            "X-Ovh-Timestamp": timestamp,
            "X-Ovh-Application": this.key
        };

        body = body ? JSON.stringify(body) : undefined;

        if (this.consumer) {
            headers["X-Ovh-Consumer"] = this.consumer
            return this.sign(method, url, body, timestamp)
                .then(hex => headers["X-Ovh-Signature"] = '$1$' + hex)
                .then(() => fetch(url, { method, headers, body }))
                .then(response => this.formatError(response));
        }

        return fetch(url, { method, headers, body })
            .then(response => this.formatError(response));
    },


    get: function (path, body) {
        return this.call('GET', path, body);
    },

    post: function (path, body) {
        return this.call('POST', path, body);
    },

    put: function (path, body) {
        return this.call('PUT', path, body);
    },

    delete: function (path, body) {
        return this.call('DELETE', path, body);
    },

    login: function (accessRules, redirection) {
        return this.post('/auth/credential', { accessRules, redirection });
    },

    logout: function () {
        return this.post('/auth/logout');
    },

    credentials: function () {
        return this.get('/auth/currentCredential');
    },

    authentication: function () {
        this.setConsumer();
        return this.get('/auth/details');
    },

    time: function () {
        return this.get('/auth/time');
    },

    me: function () {
        return this.get('/me');
    },

    connect: function () {
        this.setConsumer();

        if (this.consumer && this.validationURL) {
            return Promise.resolve();
        }

        return this.login(
            [
                {
                    method: "GET",
                    path: "/me"
                },
                {
                    method: "GET",
                    path: "/overTheBox*"
                },
                {
                    method: "POST",
                    path: "/overTheBox/*"
                },
                {
                    method: "DELETE",
                    path: "/overTheBox/*"
                }
            ],
            window.location.href
        );
    },

    services: function () {
        return this.get('/overTheBox');
    },

    service: function (serviceID) {
        return this.get('/overTheBox/' + serviceID);
    },

    device: function (serviceID) {
        return this.get('/overTheBox/' + serviceID + '/device');
    },

    linkDevice: function (serviceID, deviceID) {
        return this.post('/overTheBox/' + serviceID + '/linkDevice', { deviceId: deviceID });
    },

    unlinkDevice: function (serviceID) {
        return this.delete('/overTheBox/' + serviceID + '/device');
    }
})
