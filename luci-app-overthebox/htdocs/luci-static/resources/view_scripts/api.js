(function () {
    "use strict";

    var Api = function () {
        this.urlPrefix = "1.0/";
        this.protocole = "https";
        this.host = "eu.api.ovh.com";
        this.applicationKey = "rxaOYP724BG7eG76";
        this.applicationSecret = "4DOAMmAqBVmesDM5Jjp0mRQkBYleqded";
        this.authPath = "auth/credential";
    };

    /**
     * Define base url for all api calls
     */
    Object.defineProperty(Api.prototype, "uri", {
        get: function () {
            return this.protocole + "://" + (this.host + "/" + this.urlPrefix + "/").replace(/\/\//g, "/");
        },
        set: function () {}
    });

    /**
     * Compute API signatures
     * @param {String} method Request method (GET, PUT, ...)
     * @param {String} query  Apiv6 query
     * @param {Object} data   Data to pass in the body
     * @param {Number} ts     Timestamp in seconds
     */
    Api.prototype.getSignature = function (method, query, data, ts) {
        return "$1$" + Sha1.hash(
            [
                this.applicationSecret,
                this.consumerKey,
                method.toUpperCase(),
                query,
                data ? JSON.stringify(data) : "",
                ts
            ].join("+"));
    };

    /**
     * Perform a request to Apiv6
     * @param {Object} options See jQuery Ajax method. url will be overwritten. Specify 'path' property
     * @param {Function} callback Callback
     */
    Api.prototype.ajax = function (options/*, callback*/) {
        var callback = otb.getCallback(arguments);
        var ts = Math.round(new Date().getTime() / 1000);
        options.url = this.uri + options.path;
        options.headers = options.headers ? options.headers  : {};
        options.headers["Content-Type"] = "application/json;charset=utf-8";
        options.headers["X-Ovh-Application"] = this.applicationKey;
        options.headers["X-Ovh-Consumer"] = this.consumerKey;
        options.headers["X-Ovh-Signature"] = this.getSignature(options.method || "get", options.url, options.data, ts);
        options.headers["X-Ovh-Timestamp"] = ts;
        options.dataType = "json";
        options.data = options.data ? JSON.stringify(options.data) : options.data;
        options.success = function (data, status) {
            if (status === "success") {
                callback(null, data);
            } else {
                callback(status, data);
            }
        };
        $.ajax(options).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * Launch a poller
     * @param {Object} options: 
     *    @param {Function} caller   Api Function
     *    @param {Number}   delay    Seconds between calls
     * @return {Function} Poller destroyer
     */
    Api.prototype.startPoller = function (options) {
        var self = this;
        var isActive = true;
        var delay = options.delay ? options.delay : 5;
        var doPoll = function () {
            if (!isActive) {
                return;
            }

            options.caller(function () {
                setTimeout(doPoll, delay * 1000);
            });
        };

        doPoll();

        return function () {
            isActive = false;
        };
    };

    /**
     * Request Credentials for APIv6
     * @param {Function} callback Callback to get credentials
     */
    Api.prototype.getCredentials = function (/*, callback*/) {
        var self = this;
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: this.uri + this.authPath,
            method: "POST",
            dataType: "json",
            contentType: "application/json",
            data: JSON.stringify({
                accessRules: [
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
                redirection: window.location.href
            }),
            headers: {
                "X-Ovh-Application": this.applicationKey
            },
            success: function (data, status) {
                if (status === "success") {
                    self.tmpCredentials = data;
                    callback(null, data);
                } else {
                    callback(status, data);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * Get user Identity
     * @param {Function} callback Callback
     */
    Api.prototype.me = function (/*, callback*/) {
        var callback = otb.getCallback(arguments);
        this.ajax(
            {
                path: "me"
            },
            callback
        );
    };

    /**
     * Get OTB services
     * @param {Function} callback Callback
     */
    Api.prototype.getOtbServices = function (/*, callback*/) {
        var self = this;
        var callback = otb.getCallback(arguments);
        this.ajax(
            {
                path: "overTheBox"
            },
            function (err, list) {
                var services = [];
                var finished = 0;
                if (!err && otb.isArray(list)) {
                    if (list.length) {
                        list.forEach(function (id) {
                            self.getOtbServicesDetail(id, function(err, detail) {
                                if (!err) {
                                    services.push(detail);
                                }
                                if (++finished >= list.length) {
                                    callback(null, services);
                                }
                            });
                        });
                    } else {
                        callback(null, []);
                    }
                } else {
                    callback("Bad response");
                }
            }
        );
    };

    /**
     * Get the details of a service
     * @param {String}   serviceId Service identifier
     * @param {Function} callback  Callback
     */
    Api.prototype.getOtbServicesDetail = function (serviceId/*, callback*/) {
        var callback = otb.getCallback(arguments);
        var calls = 0;
        var result = {
            serviceName: serviceId
        };
        var error = true;
        this.ajax(
            {
                path: ["overTheBox", serviceId].join("/")
            },
            function (err, detail) {
                error = error && err;
                if (!err) {
                    Object.keys(detail).forEach(function (key) {
                        result[key] = detail[key];
                    });
                }
                if (++calls > 1) {
                    callback(error, result);
                }
            }
        );
        this.ajax(
            {
                path: ["overTheBox", serviceId, "device"].join("/")
            },
            function (err, device) {
                error = error && err;
                if (!err) {
                    result.device = device;
                }
                if (++calls > 1) {
                    callback(error, result);
                }
            }
        );
    };

    /**
     * Link the NUC to a service
     * @param {String} serviceId Identifier of the service
     * @param {String} deviceId  Identifier of the NUC
     */
    Api.prototype.linkOtbDevice = function (serviceId, deviceId/*, callback*/) {
        var callback = otb.getCallback(arguments);
        this.ajax(
            {
                path: ["overTheBox", serviceId, "linkDevice"].join("/"),
                method: "POST",
                data: {
                    deviceId: deviceId
                }
            },
            callback
        );
    };

    /**
     * Unlink the NUC from a service
     * @param {String} serviceId Identifier of the service
     */
    Api.prototype.unlinkOtbDevice = function (serviceId/*, callback*/) {
        var callback = otb.getCallback(arguments);
        this.ajax(
            {
                path: ["overTheBox", serviceId, "device"].join("/"),
                method: "DELETE"
            },
            callback
        );
    };


    // create the function containers
    if (!window.otb) {
        window.otb = new Object();
    }

    window.otb.api = new Api();

})();
