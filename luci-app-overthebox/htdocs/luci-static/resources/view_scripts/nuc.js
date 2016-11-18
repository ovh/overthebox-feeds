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
<<<<<<< HEAD
     * @param  {Integer} timeout  Lead time to check that DHCP is off
     * @param {Function} callback Callback function
     */
    Nuc.prototype.dhcpStatus = function (timeout /*, callback*/) {
        var callback = otb.getCallback(arguments);
        var self = this;
        var forceChecking = false;
=======
     * @param {Integer}  timeout  Lead time to check that DHCP is off
     * @param {Function} callback Callback function
     */
    Nuc.prototype.dhcpStatus = function (timeout/*callback*/) {
        var callback = otb.getCallback(arguments);
>>>>>>> 313b157... Add new register device wizard
        $.ajax({
            url: otb.constants.dhcpStatusURL,
            success: function (data, status) {
                if (status === "success") {
                    if (data.detected_dhcp_servers) {
                        var found = false;
                        var checking = false;
                        Object.keys(data.detected_dhcp_servers).forEach(function (index) {
                            var dhcp = data.detected_dhcp_servers[index];
<<<<<<< HEAD
                            var lastlease = parseInt(dhcp.timestamp, 10);
                            var lastcheck = parseInt(dhcp.lastcheck, 10);
                            var timestamp = Math.round(Date.now() / 1000) + (self.tsOffset !== undefined ? self.tsOffset : 0);
                            //var leaseDuring = parseInt(dhcp.lease, 10);
                            if (self.tsOffset === undefined) {
                                forceChecking = true;
                                // compute timestamp offset between client and server
                                self.tsOffset = lastcheck - timestamp;
                            }

=======
                            var lastlease = parseInt(dhcp.lease, 10);
                            var lastcheck = parseInt(dhcp.lastcheck, 10);
                            var timestamp = Math.round(Date.now() / 1000);
>>>>>>> 313b157... Add new register device wizard
                            if (lastlease && !lastcheck) {
                                found = true;
                                return;
                            }
                            if (lastlease > lastcheck) {
                                found = true;
                                return;
                            }
                            if (timestamp - lastcheck < timeout) {
                                checking = true;
                                return;
                            }

                        });
<<<<<<< HEAD

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
=======
                        var dhcpStatus = "notFound";
                        if (found) {
                            dhcpStatus = "found";
                        } else if (checking) {
                            dhcpStatus = "checking";
>>>>>>> 313b157... Add new register device wizard
                        }
                        callback(false, { status: dhcpStatus });
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
<<<<<<< HEAD
     * @param   {String} service  Service identifier
=======
     * @param {String} service Service identifier
>>>>>>> 313b157... Add new register device wizard
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
<<<<<<< HEAD
    Nuc.prototype.recievedActivationOrder = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.recievedActivationOrderURL,
            success: function (data, status) {
                if (status === "success" && data) {
                    callback(null, data.active);
=======
    Nuc.prototype.needActivateService = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.needActivateServiceURL,
            success: function (data, status) {
                if (status === "success") {
                    callback(null, data);
>>>>>>> 313b157... Add new register device wizard
                } else {
                    callback(status, false);
                }
            }
        }).fail(function (event, err, data) {
            callback(err, data);
        });
    };

    /**
<<<<<<< HEAD
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
=======
>>>>>>> 313b157... Add new register device wizard
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

<<<<<<< HEAD

    Nuc.prototype.askServiceActivation = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.askServiceActivation,
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

=======
>>>>>>> 313b157... Add new register device wizard
    /**
     * Get public IP
     * @param {Function} callback Callback function
     */
    Nuc.prototype.getPublicIp = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: "https://api.ipify.org?format=json",
            success: function (data, status) {
                if ((status === "success") && (data.ip)) {
                    callback(null, data.ip);
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
