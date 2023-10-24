'use strict';

return L.Class.extend({
    script: function (file) {
        // Create a script element
        var script = document.createElement('script');

        script.src = file;

        document.head.appendChild(script);
    }
});