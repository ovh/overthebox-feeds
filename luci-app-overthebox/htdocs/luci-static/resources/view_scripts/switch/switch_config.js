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
            case "tagged":
                this.type = "tagged";
                this.button.addClass("tagged");
                this.button.find(".type").html("tagged")
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
        var type = this.type || "lan";
        this.button = $('<button class="switch-button"><div class="name">'+ this.name +'</div><div class="type">'+ type +"</div></button>");
        this.setType(type);
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
    function readSwitches(cb, opt) {
        // Do ajax GET here

        var ports = [];
        // Add all the wans
        for (var i in opt.wans) {
          var wanPort = opt.wans[i];
          ports.push(new PortFactory({
            id: wanPort-1,
            name: wanPort,
            type: "wan",
          }));
        }
        // Add all the lans
        for (var i in opt.lans) {
          var lanPort = opt.lans[i];
          ports.push(new PortFactory({
            id: lanPort-1,
            name: lanPort,
            type: "lan",
          }));
        }
        // Add all the tagged ports
        for (var i in opt.tagged) {
          var taggedPort = opt.tagged[i];
          ports.push(new PortFactory({
            id: taggedPort-1,
            name: taggedPort,
            type: "tagged",
          }));
        }
        // Order the whole things by ID
        ports.sort(function(a, b) {
          return a.id - b.id;
        });
        // Execute callback
        cb(null, [
            {
                name: "Reset my switch",
                ports: ports,
            }
        ]);
    }

    /**
     * Group ports for display
     * @param {Array} ports Array of PortFactory
     * @return {Array} Group -> lines -> ports
     */
    function groupPorts(ports) {
        // Split the display in three groups :
        // First : All the ports < 12
        var firstGroup = ports.filter(function (port) {
          return port.id < 12;
        });
        // Second : The two wan ports
        var secondGroup = ports.filter(function (port) {
          return port.id == 12 || port.id == 13;
        });
        // Third : The 2 SFP ports 17 and 18
        var thirdGroup = ports.filter(function (port) {
          return port.id >= 15;
        });
        // Then we just split them in two lines
        return [
          [
            firstGroup.filter(function (port) {
              return port.id % 2 == 1;
            }),
            firstGroup.filter(function (port) {
              return port.id % 2 == 0;
            })
          ],
          [
            secondGroup.filter(function (port) {
              return port.id % 2 == 1;
            }),
            secondGroup.filter(function (port) {
              return port.id % 2 == 0;
            })
          ],
          [
            [],
            thirdGroup
          ]
        ];
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
    function applyConfiguration(switches, token) {
        switches.forEach(function (netSwitch) {
            var wans = netSwitch.ports
            .filter(function (port) {
                return port.isWan();
            })
            .map(function (port){
                return port.name;
            });

            // replace this with ajax POST
            $.ajax({
                url: opts.constants.setSwitchConfigUrl,
                dataType: "json",
                contentType: "application/x-www-form-urlencoded",
                method: "POST",
                data: {
                  wans: wans.join(" "),
                  token: token
                },
                success: function (data, status) {
                  // It worked
                  msgSuccess("Configuration saved. Changes will be effective soon.");
                }
            }).fail(function (event, err, data) {
              // It did not work
              console.log("ERROR WHILE APPLYING CONFIG", err, data);
              msgError("Something went wrong while applying the config");
            });

        });

    }

    /**
     * Show a success message
     * @param string
     */
    function msgSuccess(message) {
      $("#msg-success").text(message);
      $("#msg-success").show();
    }

    /**
     * Show an error message
     * @param string
     */
    function msgError(message) {
      $("#msg-danger").text(message);
      $("#msg-danger").show();
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
              var token = $(this).attr('token');
              applyConfiguration(switches, token);
            });
        }, opts);
    };

})(window);
