(function (context) {
    "use strict";

    var opts;

    /**
     * Class Port Factory
     * @param {Object} data 
     */
    var PortFactory = function (data) {
        $.extend(this, data);
    };

    /**
     * Set port type wan/lan
     * @param {String} type Either "lan" or "wan"
     */
    PortFactory.prototype.setType = function(type) {
        switch ((type || "lan").toLowerCase()) {
            case "wan":
                this.type = "wan";
                this.button.addClass("wan");
                this.button.find(".type").html("wan")
                break;
            default:
                this.type = "lan";
                this.button.removeClass("wan");
                this.button.find(".type").html("lan")
        }
    };

    /**
     * Create a button for the port
     * @param {JQuery} container Container in which the button will be created
     * @return {JQuery} the new button
     */
    PortFactory.prototype.createButton = function (container) {
        var self = this;
        this.button = $("<button class=\"switch-button\"><div class=\"name\">" + this.name + "</div><div class=\"type\">" + (this.type || "lan") + "</div></button>");
        container.append(this.button);
        this.button.bind("click", function () {
            if (self.type !== "wan") {
                self.setType("wan");
            } else {
                self.setType("lan");
            }
        })
        return this.button;
    };

    /**
     * get the port type
     * @return {Boolean} If true, the port is WAN
     */
    PortFactory.prototype.isWan = function () {
        return this.type === "wan";
    };

    /**
     * Get switches data through ajax
     * @param {Function} cb Callback (err, data)
     */
    function readSwitches(cb) {
        // Do ajax GET here

        cb(null, [
            {
                name: "Mon switch",
                ports: [
                    new PortFactory({ id:0,  name:"1",  pos:0, line:1 }),
                    new PortFactory({ id:1,  name:"2",  pos:0, line:0 }),
                    new PortFactory({ id:2,  name:"3",  pos:0, line:1 }),
                    new PortFactory({ id:3,  name:"4",  pos:0, line:0 }),
                    new PortFactory({ id:4,  name:"5",  pos:0, line:1 }),
                    new PortFactory({ id:5,  name:"6",  pos:0, line:0 }),
                    new PortFactory({ id:6,  name:"7",  pos:0, line:1 }),
                    new PortFactory({ id:7,  name:"8",  pos:0, line:0 }),
                    new PortFactory({ id:8,  name:"9",  pos:0, line:1 }),
                    new PortFactory({ id:9,  name:"10", pos:0, line:0 }),
                    new PortFactory({ id:10, name:"11", pos:0, line:1 }),
                    new PortFactory({ id:11, name:"12", pos:0, line:0 }),
                    new PortFactory({ id:12, name:"13", pos:1, line:1, type: "wans" }),
                    new PortFactory({ id:13, name:"14", pos:1, line:0, type: "wans"  }),
                    new PortFactory({ id:16, name:"17", pos:2, line:1 }),
                    new PortFactory({ id:17, name:"18", pos:2, line:1 })
                ]
            }
        ]);
    }

    /**
     * Group ports for display
     * @param {Array} ports Array of PortFactory
     * @return {Array} Group -> lines -> ports
     */
    function groupPorts(ports) {
        var maxPos = ports.reduce(function (all, port) {
            return Math.max(all, port.pos);
        }, 0);
        var maxLine = ports.reduce(function (all, port) {
            return Math.max(all, port.line);
        }, 0);
        return Array.apply(null, {length: maxPos+1}).map(function (__, pos) {
            return Array.apply(null, {length: maxLine+1}).map(function (__, line) {
                return ports.filter(function (port) {
                    return port.pos === pos && port.line === line;
                });
            });
        });
    }

    /**
     * Create a line of ports
     * @param {Array} portList Array of PortFactory
     * @param {JQuery} container Container in which the line will be created
     * @return {JQuery} The new created line
     */
    function createButtonLine (portList, container) {
        var line = $("<div class=\"portLine\"></div>");
        container.append(line);
        portList.forEach(function (port) {
            port.createButton(line);
        });
        return line;
    }

    /**
     * Create a group of ports
     * @param {Array} portLines Array of arrays of PortFactory
     * @param {JQuery} container Container in which the group will be created
     * @return {JQuery} The new created group
     */
    function createPortGroup (portLines, container) {
        var group = $("<div class=\"portGroup\"></div>");
        container.append(group);
        portLines.forEach(function (line) {
            createButtonLine (line, group);
        });
        return group;
    }

    /**
     * Create a switch
     * @param {Object} netSwitch 
     * @param {JQuery} container Container in which the switch will be created
     * @return {JQuery} The new created switch
     */
    function createSwitch (netSwitch, container) {
        var switchContainer = $("<div class=\"switch\"></div>");
        switchContainer.append("<h2>" + netSwitch.name + "</h2>");
        $("div.switches").append(switchContainer);
        groupPorts(netSwitch.ports).forEach(function (group) {
            createPortGroup (group, switchContainer);
        });
        return switchContainer;
    }

    /**
     * Perform a POST to save the configuration
     * @param {Array} switches Array of switches 
     */
    function applyConfiguration(switches) {
        switches.forEach(function (netSwitch) {
            var wans = netSwitch.ports
            .filter(function (port) {
                return port.isWan();
            })
            .map(function (port){
                return port.id;
            });

            // replace this with ajax POST
            //alert(JSON.stringify(wans));
            $.ajax({
                url: opts.constants.setSwitchConfigUrl,
                dataType: "json",
                contentType: "application/x-www-form-urlencoded",
                method: "POST",
                data: { wans: wans.join(" ") },
                success: function (data, status) {
                    alert("Yeah!");
                }
            }).fail(function (event, err, data) {
                alert("shit!");
            });

        });

    }

    /**
     * Script entry
     */
    context.initSwitches = function (options) {
        opts = options;
        readSwitches(function (err, switches) {
            switches.forEach(function (netSwitch) {
                createSwitch(netSwitch);
            });

            $("button#validateButton").bind("click", function () {
                // validate configuration here
                applyConfiguration(switches);
            });
        });
    };

})(window);