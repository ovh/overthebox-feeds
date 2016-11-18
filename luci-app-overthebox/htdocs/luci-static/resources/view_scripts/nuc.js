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
     * @param {Integer}  timeout  Lead time to check that DHCP is off
     * @param {Function} callback Callback function
     */
    Nuc.prototype.dhcpStatus = function (timeout/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.dhcpStatusURL,
            success: function (data, status) {
                if (status === "success") {
                    if (data.detected_dhcp_servers) {
                        var found = false;
                        var checking = false;
                        Object.keys(data.detected_dhcp_servers).forEach(function (index) {
                            var dhcp = data.detected_dhcp_servers[index];
                            var lastlease = parseInt(dhcp.lease, 10);
                            var lastcheck = parseInt(dhcp.lastcheck, 10);
                            var timestamp = Math.round(Date.now() / 1000);
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
                        var dhcpStatus = "notFound";
                        if (found) {
                            dhcpStatus = "found";
                        } else if (checking) {
                            dhcpStatus = "checking";
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
     * @param {String} service Service identifier
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
    Nuc.prototype.needActivateService = function (/*callback*/) {
        var callback = otb.getCallback(arguments);
        $.ajax({
            url: otb.constants.needActivateServiceURL,
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
