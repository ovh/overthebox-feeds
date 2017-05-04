(function () {
    "use strict";

    var Nuc = function () {
    };

    /**
     * Perform a DHCP check
     * @param {Function} callback Callback function
     */
    Nuc.prototype.dhcpCheck = function (/*, callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.dhcpCheckURL,
            success: function (data, status) {
                callback(status !== "success", { status: "ok" });
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * Get DHCP status
     * @param  {Integer} timeout  Lead time to check that DHCP is off
     * @param {Function} callback Callback function
     */
    Nuc.prototype.dhcpStatus = function (timeout /*, callback*/) {
        var callback = otb.getCallback(arguments);
        var self = this;
        var forceChecking = false;
        var activeDhcpList = [];
        $.ajax({
            url: otb.constants.dhcpStatusURL,
            success: function (data, status) {
                if (status === "success") {
                    if (data.detected_dhcp_servers) {
                        var found = false;
                        var checking = false;
                        Object.keys(data.detected_dhcp_servers).forEach(function (index) {
                            var dhcp = data.detected_dhcp_servers[index];
                            var lastlease = parseInt(dhcp.timestamp, 10);
                            var lastcheck = parseInt(dhcp.lastcheck, 10);
                            var timestamp = Math.round(Date.now() / 1000) + (self.tsOffset !== undefined ? self.tsOffset : 0);

                            if (self.tsOffset === undefined) {
                                forceChecking = true;
                                // compute timestamp offset between client and server
                                self.tsOffset = lastcheck - timestamp;
                            }

                            // If we have a lastlease timestamp but never checked
                            // say we found it, in order to do the first check
                            if (lastlease && !lastcheck) {
                                found = true;
                                activeDhcpList.push(dhcp);
                                return;
                            }
                            // If we got a lease after the last checking
                            // say we found it
                            if (lastlease >= lastcheck) {
                                found = true;
                                activeDhcpList.push(dhcp);
                                return;
                            }
                            // If the timeout is not reached
                            // say we're still checking
                            if (timestamp - lastcheck < timeout) {
                                checking = true;
                                return;
                            }

                            // The default value is :
                            // say we didn't find it!
                        });

                        var dhcpStatus = "notFound";
                        if (forceChecking) {
                            // this was a first call, we had to adjust timestamps between server and client
                            dhcpStatus = "checking";
                        } else {
                            if (found) {
                                dhcpStatus = "found";
                            } else if (checking) {
                                dhcpStatus = "checking";
                            }
                        }
                        callback(false, { status: dhcpStatus, activeDhcpList: activeDhcpList });
                    } else {
                        callback(false, { status: "notFound" });
                    }
                } else {
                    callback(status, {});
                }
            }
        }).fail(function (event, err, data) {
            callback(err, { error: data });
        });
    };

    /**
     * Activate service
     * @param   {String} service  Service identifier
     * @param {Function} callback Callback function
     */
    Nuc.prototype.activateService = function (service/*, callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: [otb.constants.serviceActivateURL, service].join("/"),
            dataType: "text",
            success: function (data, status) {
                if (status === "success") {
                    callback(null, data);
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * Check if service need to be activated
     * @param {Function} callback Callback function
     */
    Nuc.prototype.recievedActivationOrder = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.recievedActivationOrderURL,
            success: function (data, status) {
                if (status === "success" && data) {
                    callback(null, data.active);
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * Check if serviceActivation is needed
     * @param {Function} callback Callback function
     * @return {Function} poller stoping function
     */
    Nuc.prototype.needServiceActivation = function(/*callback*/) {
        var callback = otb.getCallback(arguments);
        var counter = 0
        var poller = otb.api.startPoller({
            delay: 2,
            caller: function (cb) {
                if (counter > 15) {
                    poller();
                    callback(null, {status: "done", needActivation: false});
                } else {
                    otb.nuc.recievedActivationOrder(function(err, status) {
                        if (!err && status === false) {
                            poller();
                            callback(null, {status: "done", needActivation: true});
                        } else {
                            callback(null, {status: "pending", progress: Math.round(100*counter/15)});
                        }
                        cb();
                    });
                }
                counter++;
            }
        });
        callback(null, {status: "pending", progress: 0});

        return function() {
            poller();
        }
    }

    /**
     * Get the status of all interfaces
     * @param {Function} callback Callback function
     */
    Nuc.prototype.interfacesStatus = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.interfaceStatusURL,
            success: function (data, status) {
                if (status === "success") {
                    callback(null, data);
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * get connected modems
     * @param {Function} callback Callback function
     */
    Nuc.prototype.connectedModems = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.interfaceStatusURL,
            success: function (data, status) {
                if ((status === "success") && (data.wans)) {
                    callback(null, data.wans);
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * Ask for a service activation
     * @param {Function} callback Callback function
     */
    Nuc.prototype.askServiceActivation = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.askServiceActivationURL,
            success: function (data, status) {
                if ((status === "success") && (data.wans)) {
                    callback(null, data.wans);
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
     * Change the password of root on the nuc
     * @param {String} token     Token available in lua vat 'token'
     * @param {String} password1 Password
     * @param {String} password2 Repeat password
     * @param {Function} callback Callback function
     */
    Nuc.prototype.changePassword = function(token, password1, password2 /*, callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.changePasswordURL,
            method: "POST",
            dataType: "json",
            contentType: "application/x-www-form-urlencoded",
            data: {
                p1: password1,
                p2: password2,
                token: token
            },
            success: function (data, status) {
                if ((status === "success")) {
                    callback(null, data);
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    }

    /**
     * Get public IP
     * @param {Function} callback Callback function
     */
    Nuc.prototype.getPublicIp = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: "https://ipaddr.ovh",
            success: function (data, status) {
                if ((status === "success") && (data)) {
                    callback(null, data.trim());
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    // create the function containers
    if (!window.otb) {
        window.otb = new Object();
    }

    window.otb.nuc = new Nuc();

})();
