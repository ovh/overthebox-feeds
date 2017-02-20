(function () {
    "use strict";

    // create the function containers
    if (!window.otb) {
        window.otb = new Object();
    }

    var Translation = function() {
        this.data = {};
    }

    /**
     * Append a translation
     * @param {String} key   Translation key
     * @param {String} value Translated string. for replacement, use {{var1}}. For instance add("key1", Hello {{name}} !")
     */
    Translation.prototype.add = function (key, value) {
        this.data[key] = value;
    }

    /**
     * Get a translation string
     * @param {String} key        Translation key
     * @param {Object} injections values to injection. For instance get("key1", {name: "world"})
     * @return {String}
     */
    Translation.prototype.get = function(key, injections) {
        return this.data[key].replace(/\{\{([^\}]+)\}\}/g, function(replacement, key) {
            return injections ? injections[key] : replacement;
        });
    }

    window.otb.translations = new Translation();

})();