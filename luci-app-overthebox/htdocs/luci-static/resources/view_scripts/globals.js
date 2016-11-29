(function () {
    "use strict";

    // create the function containers
    if (!window.otb) {
        window.otb = new Object();
    }

    /**
     * Check if parameters are a JQuery element
     * @param {JQuery} jqElt1 Element to check
     * @param {JQuery} jqElt2 Element to check
     * ...
     * @return {Boolean}
     */
    window.otb.isJquery = function (/*jqElt1, jqElt2, ...*/) {
        return Array.prototype.slice.call(arguments).reduce(function (all, jqElt) {
            return all && (jqElt instanceof jQuery) && (jqElt.length > 0);
        }, true);
    };

    /**
     * Extract a callback fonction from arguments
     * @param {Array} args Parent function argument list
     * @return {Function}
     */
    window.otb.getCallback = function (args) {
        var lastArg = args[args.length - 1];
        if (typeof lastArg === "function") {
            return lastArg;
        } else {
            return function () {};
        }
    };

    /**
     * Push a message in jqDest
     * @param {jQuery} jqDest   Destination containers
     * @param {String} type     success|info|warning|error
     * @param {String} html     HTML representation of the message
     * @param {Number} duration duration of the message in seconds. if nothing specified, the message is permanent
     */
    window.otb.pushMessage = function (jqDest, type, html, duration) {
        if (!otb.isJquery(jqDest)) {
            return window.otb;
        }
        var message = $("<div role=\"alert\" class=\"oui-message oui-message_" + type + "\">" + html + "<button type=\"button\" class=\"oui-message__close-button\" aria-label=\"Close\"></button></div>");
        jqDest.append(message);
        message.find($("button.oui-message__close-button")).click(function () {
            message.remove();
        });
        if (duration) {
            setTimeout(
                function () {
                    message.animate({ height: 0, opacity: 0 }, "slow", function () {
                        message.remove();
                    });
                },
                duration * 1000
            );
        }
        return window.otb;
    };

    /**
     * Find the first element in an array with criteria
     * @param  {Array} list      List to search in
     * @param {Object} predicate criteria
     * @return {Any} Found object or null
     */
    window.otb.arrayFind = function (list, predicate) {
        var filtered = (list || []).filter(function (elt) {
            return Object.keys(predicate).reduce(function (total, key) {
                return total && (predicate[key] === elt[key]);
            }, true);
        });
        if (filtered.length) {
            return filtered[0];
        }
        return null;
    };

    /**
     * Check if obj is an array
     * @param {Any} Obj Variable to test
     * @return {Boolean}
     */
    window.otb.isArray = function (obj) {
        return Object.prototype.toString.call(obj) === "[object Array]";
    };

    /**
     * Add/Remove a spinner
     * @param  {JQuery} jqDest Container for the spinner
     * @param {Boolean} enable On/Off
     */
    window.otb.spinner = function (jqDest, enable) {
        if (!otb.isJquery(jqDest)) {
            return window.otb;
        }
        var insert = enable ? "<div class=\"spinner-volume\"><div class=\"volume\"></div><div class=\"volume\"></div><div class=\"volume\"></div><div class=\"volume\"></div></div>" : "";
        jqDest.html(insert);
        return window.otb;
    };

    /**
     * Add a class to a svg element
     * @param {JQuery} jqDest Elements on which to add a class
     * @param {String} classe Class name
     */
    window.otb.svgAddClass = function (jqDest, classe) {
        if (!otb.isJquery(jqDest)) {
            return window.otb;
        }
        jqDest.each(function (i, elt) {
            var classes = $(elt).attr("class").split(/\s+/);
            var index = classes.indexOf(classe);
            if (index === -1) {
                classes.push(classe);
                $(elt).attr("class", classes.join(" "));
            }
        });
        return window.otb;
    };

    /**
     * Remove a class from a svg element
     * @param {JQuery} jqDest Elements on which to remove the class
     * @param {String} classe Class name to remove
     */
    window.otb.svgRemoveClass = function (jqDest, classe) {
        if (!otb.isJquery(jqDest)) {
            return window.otb;
        }
        jqDest.each(function (i, elt) {
            var classes = $(elt).attr("class").split(/\s+/);
            var index = classes.indexOf(classe);
            if (index !== -1) {
                classes.splice(index, 1);
                $(elt).attr("class", classes.join(" "));
            }
        });
        return window.otb;
    };

    /**
     * No operation function
     */
    window.otb.noop = function() {};

})();