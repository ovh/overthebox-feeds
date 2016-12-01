(function () {
    "use strict";

    /**
     * generate a UUID
     * @return {String} UUID
     */
    function generateUUID() {
        var d = new Date().getTime();
        var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = (d + Math.random()*16)%16 | 0;
            d = Math.floor(d/16);
            return (c=='x' ? r : (r&0x3|0x8)).toString(16);
        });
        return uuid;
    };

    /**
     * Attach events
     * @param {String}   stepId       Wizard step identifier
     * @param {String}   name         Event name
     * @param {Function} callback     event to attach
     */
    function attachEvent (stepId, name, callback) {
        var wizardEvents = this.data("events") ? this.data("events") : {};
        wizardEvents[stepId] = wizardEvents[stepId] ? wizardEvents[stepId] : {};
        wizardEvents[stepId][name] = callback;
        this.data("events", wizardEvents);
    };

    /**
     * Get an event
     * @param {String}   stepId       Wizard step identifier
     * @param {String}   name         Event name
     * @return {Function} event
     */
    function getEvent(stepId, name) {
        var wizardEvents = this.data("events") ? this.data("events") : {};
        if (wizardEvents[stepId] && wizardEvents[stepId][name]) {
            return wizardEvents[stepId][name];
        } else {
            return function() {};
        }
    }

    /**
     * Go to a wizard step
     * @param {String|JQuery} stepId step identifier of step jquery object
     * @param {Function} callback     event to attach
     */
    function gotoStep (stepId/*, callback*/) {
        var self = this;
        var callback = otb.getCallback(arguments);
        var currentJq;
        var subRoute = "";
        if (typeof stepId === "string") {
            subRoute = stepId.replace(/^[^\/]*/, "");
            currentJq = $("#" + stepId.replace(/\/.*/, ""));
        } else {
            currentJq = stepId;
        }
        if (!currentJq.length) {
            return;
        }
        var parent  = currentJq.parent();
        var id = currentJq.get(0).id;
        window.location.hash = id + subRoute;
        var currentStatus = "done";
        var index = 0;
        parent.children().each(function () {
            var wasActive = $(this).attr("class").indexOf("ongoing") > -1;
            if (currentStatus === "ongoing") {
                currentStatus = "todo";
            }
            if (this.id === id) {
                currentStatus = "ongoing";
                parent.data("wizardIndex", index);
            }
            $(this).attr("class", currentStatus);

            if (wasActive) {
                getEvent.apply(self, [this.id, "stop"])();
            }
            index++;
        });
        var containerId = currentJq.data("container");
        $("#" + containerId).parent().children().hide();
        $("#" + containerId).show();
        getEvent.apply(this, [id, "start"])();
        callback();
    };

    /**
     * Go to the next step of the wizard
     * @param {JQuery} jqWizard Wizard
     */
    window.otb.wizardNext = function (jqWizard/*, callback*/) {
        var callback = otb.getCallback(arguments);
        var index = jqWizard.data("wizardIndex") + 1;
        if (index < jqWizard.children().length) {
            var target =  jqWizard.children().eq(index);
            window.otb.wizardGoto(target, callback);
        }
    };

    /**
     * Wizard manager
     * <ul>
     *    <li data-container="bob">
     *    <li data-container="foo">
     * </ul>
     * <div>
     *   <div id="bob">first step</div>
     *   <div id="foo">second step</div>
     * </div>
     * $("ul").wizard(); => initialize wizard
     * $("ul").wizard("attachEvent", "bob", "start", function(){}) => attach event
     * $("ul").wizard("attachEvent", "bob", "stop", function(){}) => attach event
     * $("ul").wizard("goto", "foo", function() {}) => go to "foo" step
     * $("ul").wizard("first", function() {}) => go to "bob" step
     * $("ul").wizard("next", function() {}) => go to "foo" step
     * $("ul").wizard("currentId") => get current step name
     * $("ul").wizard("has", "foo") => return true if step name exists
     */
    var Wizard = function() {
        if (!this.data("id")) {
            this.children().each(function(index, element) {
                var container = $("#" + $(element).data("container"));
                container.hide();
            });
            this.data("wizardIndex", 0);
            this.data("id", generateUUID());
            this.data(this.data("events") ? this.data("events") : {});
        }

        var args = Array.prototype.slice.call(arguments)
        if (args.length) {
            var action = args.shift();
            switch (action) {
                case "goto":
                    gotoStep.apply(this, args)
                    break;
                case "attachEvent":
                    attachEvent.apply(this, args);
                    break;
                case "next":
                    var callback = otb.getCallback(arguments);
                    var index = this.data("wizardIndex") + 1;
                    if (index < this.children().length) {
                        var target =  this.children().eq(index);
                        gotoStep.apply(this, [target, callback])
                    }
                    break;
                case "has":
                    var id = args[0];
                    if (!id) {
                        return false;
                    }
                    return !!this.has("#" + id.replace(/\/.*$/, "")).length;
                case "currentId":
                    return this.get(0).id;
                case "first":
                    var callback = otb.getCallback(arguments);
                    var target =  this.children().eq(0);
                    gotoStep.apply(this, [target, callback])
                    break;
                default:
                    console.warn(action, "not supported");
            }
        }
        return this;
    }

    $.fn.wizard = Wizard;

})();