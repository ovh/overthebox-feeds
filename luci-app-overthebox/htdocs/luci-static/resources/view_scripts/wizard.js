(function () {
    "use strict";

    // create the function containers
    if (!window.otb) {
        window.otb = new Object();
    }

    window.otb.wizardCallbacks = {};

    /**
     * Check if a wizard has an id
     * @param {JQuery} jqWizard Wizard
     * @param {String} id       Identifier
     */
    window.otb.wizardHas = function (jqWizard, id) {
        if (!id) {
            return false;
        }
        if (!otb.isJquery(jqWizard)) {
            return false;
        }
        return !!jqWizard.has("#" + id).length;
    };

    /**
     * Goto a wizard step
     * @param {JQuery} jqWizardStep Step to activate
     */
    window.otb.wizardGoto = function (jqWizardStep/*, callback*/) {
        var callback = otb.getCallback(arguments);
        if (!otb.isJquery(jqWizardStep)) {
            callback();
            return window.otb;
        }
        var elt = jqWizardStep.get(0);
        var events = otb.arrayFind(window.otb.wizard, { dom: elt });
        var parent  = $(elt).parent();
        var id = elt.id;
        window.location.hash = id;
        var currentStatus = "done";
        var index = 0;
        parent.children().each(function () {
            var wasActive = $(this).attr("class").indexOf("ongoing") > -1;
            var currentEvents = otb.arrayFind(window.otb.wizard, { dom: this });
            if (currentStatus === "ongoing") {
                currentStatus = "todo";
            }
            if (this.id === id) {
                currentStatus = "ongoing";
                parent.data("wizardIndex", index);
            }
            $(this).attr("class", currentStatus);
            if (wasActive && currentEvents && currentEvents.stop) {
                currentEvents.stop();
            }
            /*if (currentStatus === "done") {
                $(this).click(function () {
                    location.hash = "#" + $(this).attr("id");
                });
            } else {
                $(this).unbind("click");
            }*/
            index++;
        });
        $("#process").children().hide();
        $("#" + id + "Process").show();
        if (events && events.start) {
            events.start();
        }
        callback();
        return window.otb;
    };

    /**
     * Go to the next step of the wizard
     * @param {JQuery} jqWizard Wizard
     */
    window.otb.wizardNext = function (jqWizard/*, callback*/) {
        var callback = otb.getCallback(arguments);
        if (!otb.isJquery(jqWizard)) {
            callback();
            return window.otb;
        }
        var index = jqWizard.data("wizardIndex") + 1;
        if (index < jqWizard.children().length) {
            var target =  jqWizard.children().eq(index);
            window.otb.wizardGoto(target, callback);
        }
        return window.otb;
    };

    /**
     * Attach events
     * @param {JQuery}   jqWizardStep Wizard step
     * @param {String}   name         Event name
     * @param {Function} callback     event to attach
     */
    window.otb.wizardAttachEvent = function (jqWizardStep, name, callback) {
        if (!otb.isJquery(jqWizardStep)) {
            return callback();
        }
        window.otb.wizard = Object.prototype.toString.call(window.otb.wizard) === "[object Array]" ? window.otb.wizard : [];
        var elt = jqWizardStep.get(0);
        var events = otb.arrayFind(window.otb.wizard, { dom: elt });
        if (events) {
            events[name] = callback;
        } else {
            var newEvent = { dom: elt };
            newEvent[name] = callback;
            window.otb.wizard.push(newEvent);
        }
        return window.otb;
    };


})();