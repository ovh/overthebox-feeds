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
     * Append a connection picture to jqDest
     * @param {JQuery} jqDest Target of the pic
     */
    window.otb.connectionScheme = function (jqDest) {
        if (!otb.isJquery(jqDest)) {
            return window.otb;
        }
        jqDest.html("<g transform=\"scale(0.3)\" class=\"connexion-scheme\"><g id=\"otb\"><path class=\"st0\" d=\"M363.4,305.2H51.2c-12.8,0-23.3-10.5-23.3-23.3V158.5c0-12.8,10.5-23.3,23.3-23.3h312.2c12.8,0,23.3,10.5,23.3,23.3v123.4C386.7,294.7,376.2,305.2,363.4,305.2z\"/><line class=\"st0\" x1=\"27.9\" y1=\"166.9\" x2=\"311.9\" y2=\"166.9\"/><line class=\"st0\" x1=\"339.2\" y1=\"166.9\" x2=\"385.9\" y2=\"166.9\"/><path class=\"st0\" d=\"M242,220.2c3.2,5.8,5.1,12.4,5.1,19.5c0,22-17.8,39.8-39.8,39.8s-39.8-17.8-39.8-39.8s17.8-39.8,39.8-39.8c6.6,0,12.9,1.6,18.4,4.5\"/><circle class=\"st0\" cx=\"207.3\" cy=\"238.5\" r=\"12.4\"/><path class=\"st0\" d=\"M88,320.2H56.4c-2.3,0-4.1-1.9-4.1-4.1v-6.7c0-2.3,1.9-4.1,4.1-4.1H88c2.3,0,4.1,1.9,4.1,4.1v6.7C92.1,318.3,90.2,320.2,88,320.2z\"/><path class=\"st0\" d=\"M357.3,320.2h-31.6c-2.3,0-4.1-1.9-4.1-4.1v-6.7c0-2.3,1.9-4.1,4.1-4.1h31.6c2.3,0,4.1,1.9,4.1,4.1v6.7C361.4,318.3,359.6,320.2,357.3,320.2z\"/></g><g id=\"cloud_label\"><g><path class=\"st1\" d=\"M1314.2,244.7h-4.1v-31.3h4.1V244.7z\"/><path class=\"st1\" d=\"M1324.9,221.4l0.1,2.9c0.8-1,1.8-1.9,3-2.5c1.2-0.6,2.5-0.9,4-0.9c1.1,0,2.2,0.2,3.1,0.5c0.9,0.3,1.7,0.8,2.3,1.5c0.6,0.7,1.1,1.6,1.5,2.6c0.4,1.1,0.5,2.4,0.5,3.9v15.2h-4v-15.3c0-0.9-0.1-1.7-0.3-2.3c-0.2-0.6-0.5-1.2-0.9-1.6c-0.4-0.4-0.9-0.7-1.5-0.9c-0.6-0.2-1.2-0.3-2-0.3c-1.3,0-2.4,0.3-3.4,1c-1,0.7-1.7,1.6-2.3,2.7v16.6h-4v-23.2H1324.9z\"/><path class=\"st1\" d=\"M1350.8,215.8v5.6h4.3v3.1h-4.3v14.4c0,0.6,0.1,1.1,0.2,1.5c0.1,0.4,0.3,0.6,0.6,0.8c0.2,0.2,0.5,0.3,0.8,0.4c0.3,0.1,0.6,0.1,1,0.1c0.3,0,0.7,0,1-0.1s0.6-0.1,0.8-0.2v3.2c-0.3,0.1-0.7,0.2-1.2,0.3c-0.5,0.1-1.1,0.2-1.8,0.2c-0.7,0-1.4-0.1-2.1-0.3c-0.7-0.2-1.2-0.6-1.7-1c-0.5-0.5-0.9-1.1-1.2-1.9c-0.3-0.8-0.4-1.8-0.4-2.9v-14.4h-4.2v-3.1h4.2v-5.6H1350.8z\"/><path class=\"st1\" d=\"M1369.4,245.1c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5V233c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8c0.9-1,2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8h-15.7c0,1.1,0.2,2.1,0.5,3c0.3,0.9,0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6c0.8,0.4,1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4c-0.7,0.4-1.5,0.8-2.4,1C1371.6,245,1370.6,245.1,1369.4,245.1z M1368.9,224.3c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9h11.6v-0.3c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5C1370.8,224.5,1369.9,224.3,1368.9,224.3z\"/><path class=\"st1\" d=\"M1394.3,225c-0.3-0.1-0.7-0.1-1-0.1c-0.3,0-0.6,0-1,0c-1.4,0-2.5,0.3-3.4,0.9c-0.9,0.6-1.5,1.4-1.9,2.4v16.5h-4v-23.2h3.9l0.1,2.7c0.6-1,1.4-1.7,2.3-2.3s2-0.8,3.3-0.8c0.3,0,0.6,0,1,0.1c0.4,0.1,0.6,0.1,0.8,0.2V225z\"/><path class=\"st1\" d=\"M1401.7,221.4l0.1,2.9c0.8-1,1.8-1.9,3-2.5c1.2-0.6,2.5-0.9,4-0.9c1.1,0,2.2,0.2,3.1,0.5c0.9,0.3,1.7,0.8,2.3,1.5c0.6,0.7,1.1,1.6,1.5,2.6c0.4,1.1,0.5,2.4,0.5,3.9v15.2h-4v-15.3c0-0.9-0.1-1.7-0.3-2.3c-0.2-0.6-0.5-1.2-0.9-1.6c-0.4-0.4-0.9-0.7-1.5-0.9c-0.6-0.2-1.2-0.3-2-0.3c-1.3,0-2.4,0.3-3.4,1c-1,0.7-1.7,1.6-2.3,2.7v16.6h-4v-23.2H1401.7z\"/><path class=\"st1\" d=\"M1431.9,245.1c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5V233c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8c0.9-1,2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8h-15.7c0,1.1,0.2,2.1,0.5,3c0.3,0.9,0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6c0.8,0.4,1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4c-0.7,0.4-1.5,0.8-2.4,1C1434.1,245,1433,245.1,1431.9,245.1z M1431.4,224.3c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9h11.6v-0.3c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5C1433.3,224.5,1432.4,224.3,1431.4,224.3z\"/><path class=\"st1\" d=\"M1450.9,215.8v5.6h4.3v3.1h-4.3v14.4c0,0.6,0.1,1.1,0.2,1.5c0.1,0.4,0.3,0.6,0.6,0.8c0.2,0.2,0.5,0.3,0.8,0.4c0.3,0.1,0.6,0.1,1,0.1c0.3,0,0.7,0,1-0.1s0.6-0.1,0.8-0.2v3.2c-0.3,0.1-0.7,0.2-1.2,0.3c-0.5,0.1-1.1,0.2-1.8,0.2c-0.7,0-1.4-0.1-2.1-0.3c-0.7-0.2-1.2-0.6-1.7-1c-0.5-0.5-0.9-1.1-1.2-1.9c-0.3-0.8-0.4-1.8-0.4-2.9v-14.4h-4.2v-3.1h4.2v-5.6H1450.9z\"/></g></g><g id=\"otb_label\"><path class=\"st1\" d=\"M116.9,375.4c0,2.3-0.3,4.5-0.9,6.3c-0.6,1.9-1.4,3.4-2.5,4.7c-1.1,1.3-2.4,2.3-4,3s-3.3,1-5.2,1c-1.8,0-3.5-0.3-5.1-1s-2.9-1.7-4-3s-2-2.9-2.6-4.7c-0.6-1.9-0.9-4-0.9-6.3v-2c0-2.3,0.3-4.4,0.9-6.3c0.6-1.9,1.5-3.5,2.6-4.8c1.1-1.3,2.4-2.3,4-3s3.2-1,5.1-1c1.9,0,3.6,0.3,5.2,1c1.6,0.7,2.9,1.7,4,3s1.9,2.9,2.5,4.8c0.6,1.9,0.9,4,0.9,6.3V375.4z M112.8,373.4c0-1.9-0.2-3.5-0.6-4.9c-0.4-1.4-0.9-2.6-1.7-3.6s-1.6-1.7-2.7-2.2s-2.2-0.8-3.6-0.8c-1.3,0-2.4,0.3-3.5,0.8c-1,0.5-1.9,1.2-2.7,2.2c-0.7,1-1.3,2.2-1.7,3.6c-0.4,1.4-0.6,3.1-0.6,4.9v2c0,1.9,0.2,3.5,0.6,5s1,2.6,1.7,3.6c0.7,1,1.6,1.7,2.7,2.2c1,0.5,2.2,0.8,3.5,0.8c1.3,0,2.5-0.3,3.6-0.8c1-0.5,1.9-1.2,2.7-2.2c0.7-1,1.3-2.2,1.6-3.6c0.4-1.4,0.6-3.1,0.6-5V373.4z\"/><path class=\"st1\" d=\"M130.2,384.6l5.8-17.9h4.1l-8.3,23.2h-3l-8.4-23.2h4.1L130.2,384.6z\"/><path class=\"st1\" d=\"M153.2,390.4c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5v-0.9c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8s2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8h-15.7c0,1.1,0.2,2.1,0.5,3s0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6s1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4s-1.5,0.8-2.4,1C155.4,390.3,154.3,390.4,153.2,390.4z M152.7,369.6c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9h11.6V376c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5S153.7,369.6,152.7,369.6z\"/><path class=\"st1\" d=\"M178.1,370.3c-0.3-0.1-0.7-0.1-1-0.1c-0.3,0-0.6,0-1,0c-1.4,0-2.5,0.3-3.4,0.9c-0.9,0.6-1.5,1.4-1.9,2.4V390h-4v-23.2h3.9l0.1,2.7c0.6-1,1.4-1.7,2.3-2.3s2-0.8,3.3-0.8c0.3,0,0.6,0,1,0.1c0.4,0.1,0.6,0.1,0.8,0.2V370.3z\"/><path class=\"st1\" d=\"M204,362.1h-10.1V390h-4.1v-27.9h-10v-3.4H204V362.1z\"/><path class=\"st1\" d=\"M212,369.6c0.8-1,1.8-1.8,3-2.4s2.5-0.9,3.9-0.9c1.1,0,2.2,0.2,3.1,0.5c0.9,0.3,1.7,0.8,2.3,1.5s1.1,1.6,1.5,2.6c0.4,1.1,0.5,2.4,0.5,3.9V390h-4v-15.3c0-0.9-0.1-1.7-0.3-2.3c-0.2-0.6-0.5-1.2-0.9-1.6c-0.4-0.4-0.9-0.7-1.5-0.9s-1.2-0.3-2-0.3c-1.3,0-2.4,0.3-3.4,1c-1,0.7-1.7,1.6-2.3,2.7V390h-4v-33h4V369.6z\"/><path class=\"st1\" d=\"M241.9,390.4c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5v-0.9c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8s2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8h-15.7c0,1.1,0.2,2.1,0.5,3s0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6s1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4s-1.5,0.8-2.4,1C244.1,390.3,243,390.4,241.9,390.4z M241.4,369.6c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9H247V376c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5S242.4,369.6,241.4,369.6z\"/><path class=\"st1\" d=\"M256.1,390v-31.3h10.2c1.6,0,3,0.2,4.3,0.5c1.3,0.3,2.3,0.8,3.2,1.5s1.6,1.5,2,2.6c0.5,1,0.7,2.3,0.7,3.8s-0.4,2.8-1.2,3.9c-0.8,1.1-2,2-3.4,2.6c0.9,0.2,1.7,0.6,2.3,1.1c0.7,0.5,1.3,1,1.7,1.7c0.5,0.6,0.8,1.4,1.1,2.2c0.2,0.8,0.4,1.6,0.4,2.5c0,1.5-0.2,2.8-0.7,3.9s-1.2,2.1-2.1,2.8s-2,1.3-3.3,1.7c-1.3,0.4-2.7,0.6-4.3,0.6H256.1z M260.3,372.1h6.2c0.9,0,1.7-0.1,2.4-0.3s1.4-0.6,1.9-1c0.5-0.4,0.9-1,1.2-1.6c0.3-0.6,0.4-1.3,0.4-2.1c0-1.7-0.5-3-1.5-3.7c-1-0.8-2.5-1.2-4.6-1.2h-6.1V372.1z M260.3,375.4v11.3h6.8c1,0,1.9-0.1,2.6-0.4c0.8-0.3,1.4-0.6,1.9-1.1c0.5-0.5,0.9-1.1,1.2-1.8s0.4-1.5,0.4-2.3s-0.1-1.6-0.3-2.3c-0.2-0.7-0.6-1.3-1.1-1.8s-1.1-0.9-1.9-1.1c-0.8-0.3-1.7-0.4-2.7-0.4H260.3z\"/><path class=\"st1\" d=\"M281.9,378.2c0-1.7,0.2-3.3,0.7-4.7s1.2-2.7,2.1-3.7c0.9-1.1,2-1.9,3.3-2.5c1.3-0.6,2.8-0.9,4.4-0.9c1.6,0,3.1,0.3,4.4,0.9s2.4,1.4,3.3,2.5c0.9,1.1,1.6,2.3,2.1,3.7c0.5,1.4,0.7,3,0.7,4.7v0.5c0,1.7-0.2,3.3-0.7,4.7c-0.5,1.4-1.2,2.7-2.1,3.7c-0.9,1.1-2,1.9-3.3,2.5c-1.3,0.6-2.8,0.9-4.4,0.9s-3.1-0.3-4.4-0.9c-1.3-0.6-2.4-1.4-3.3-2.5c-0.9-1.1-1.6-2.3-2.1-3.7s-0.7-3-0.7-4.7V378.2z M285.9,378.6c0,1.2,0.1,2.3,0.4,3.3c0.3,1,0.7,1.9,1.2,2.7c0.6,0.8,1.2,1.4,2.1,1.9c0.8,0.5,1.8,0.7,2.9,0.7c1.1,0,2-0.2,2.9-0.7c0.8-0.5,1.5-1.1,2.1-1.9c0.5-0.8,1-1.7,1.2-2.7s0.4-2.1,0.4-3.3v-0.5c0-1.1-0.1-2.2-0.4-3.3s-0.7-1.9-1.2-2.7c-0.6-0.8-1.2-1.4-2.1-1.9c-0.8-0.5-1.8-0.7-2.9-0.7c-1.1,0-2,0.2-2.9,0.7s-1.5,1.1-2.1,1.9c-0.6,0.8-1,1.7-1.2,2.7c-0.3,1-0.4,2.1-0.4,3.3V378.6z\"/><path class=\"st1\" d=\"M315.4,375.3l5.2-8.5h4.6l-7.6,11.5l7.8,11.8h-4.6l-5.4-8.7l-5.4,8.7h-4.6l7.8-11.8l-7.6-11.5h4.6L315.4,375.3z\"/></g><path id=\"cloud\" class=\"st2\" d=\"M1479.8,167.1c-8.8,0-17.2,1.6-25,4.5c-14.9-31.3-46.9-52.9-83.8-52.9c-46.2,0-84.3,33.9-91.4,78.1c-6.2-2.4-13-3.9-20-3.9c-30.8,0-55.7,25-55.7,55.7c0,30.7,24.9,55.7,55.7,53.1h111.4c20.2,1,87,0,108.9,0c39.8,0,72.1-22.7,72.1-62.5C1551.9,199.4,1519.6,167.1,1479.8,167.1z\"/><line id=\"connect1\" class=\"st0 jsModem1\" x1=\"385.9\" y1=\"227.7\" x2=\"670.4\" y2=\"227.7\"/><line id=\"internet1\" class=\"st0 jsModem1\" x1=\"926\" y1=\"227.7\" x2=\"1210.5\" y2=\"227.7\"/><line id=\"internet2\" class=\"st0 jsModem2\" x1=\"926\" y1=\"392\" x2=\"1203.8\" y2=\"228.8\"/><line id=\"internet4\" class=\"st0 jsModem4\" x1=\"926\" y1=\"72.6\" x2=\"1207.9\" y2=\"227.7\"/><line id=\"internet3\" class=\"st0 jsModem3\" x1=\"926\" y1=\"546.9\" x2=\"1206.3\" y2=\"232\"/><polyline id=\"connect2\" class=\"st0 jsModem2\" points=\"672.5,250.9 619.1,250.9 619.1,384.7 672.5,384.7 \"/><polyline id=\"connect3\" class=\"st0 jsModem3\" points=\"672.5,409.2 619.1,409.2 619.1,542.9 672.5,542.9 \"/><polyline id=\"connect4\" class=\"st0 jsModem4\" points=\"672.5,203.6 619.1,203.6 619.1,69.8 672.5,69.8 \"/><g id=\"modem4\" class=\"jsModem4\"><path class=\"st0\" d=\"M922,148.5H676.5c-2.2,0-4-1.8-4-4v-123c0-2.2,1.8-4,4-4H922c2.2,0,4,1.8,4,4v123C926,146.7,924.2,148.5,922,148.5z\"/><g><path class=\"st1\" d=\"M719.6,65.7l10.2,25.5l10.2-25.5h5.3V97h-4.1V84.8l0.4-13.1L731.4,97h-3.2L718,71.7l0.4,13.1V97h-4.1V65.7H719.6z\"/><path class=\"st1\" d=\"M751,85.2c0-1.7,0.2-3.3,0.7-4.7s1.2-2.7,2.1-3.7c0.9-1.1,2-1.9,3.3-2.5c1.3-0.6,2.8-0.9,4.4-0.9c1.6,0,3.1,0.3,4.4,0.9s2.4,1.4,3.3,2.5c0.9,1.1,1.6,2.3,2.1,3.7c0.5,1.4,0.7,3,0.7,4.7v0.5c0,1.7-0.2,3.3-0.7,4.7c-0.5,1.4-1.2,2.7-2.1,3.7c-0.9,1.1-2,1.9-3.3,2.5c-1.3,0.6-2.8,0.9-4.4,0.9s-3.1-0.3-4.4-0.9c-1.3-0.6-2.4-1.4-3.3-2.5c-0.9-1.1-1.6-2.3-2.1-3.7s-0.7-3-0.7-4.7V85.2z M755,85.6c0,1.2,0.1,2.3,0.4,3.3c0.3,1,0.7,1.9,1.2,2.7c0.6,0.8,1.2,1.4,2.1,1.9c0.8,0.5,1.8,0.7,2.9,0.7c1.1,0,2-0.2,2.9-0.7c0.8-0.5,1.5-1.1,2.1-1.9c0.5-0.8,1-1.7,1.2-2.7s0.4-2.1,0.4-3.3v-0.5c0-1.1-0.1-2.2-0.4-3.3c-0.3-1-0.7-1.9-1.2-2.7c-0.6-0.8-1.2-1.4-2.1-1.9c-0.8-0.5-1.8-0.7-2.9-0.7c-1.1,0-2,0.2-2.9,0.7c-0.8,0.5-1.5,1.1-2.1,1.9c-0.6,0.8-1,1.7-1.2,2.7c-0.3,1-0.4,2.1-0.4,3.3V85.6z\"/><path class=\"st1\" d=\"M776.2,85.2c0-1.8,0.2-3.4,0.7-4.8c0.4-1.5,1.1-2.7,1.9-3.7c0.8-1,1.8-1.8,2.9-2.4c1.1-0.6,2.4-0.9,3.8-0.9c1.4,0,2.7,0.2,3.7,0.7c1.1,0.5,2,1.2,2.8,2.1V64h4v33h-3.7l-0.2-2.5c-0.8,0.9-1.7,1.7-2.8,2.2c-1.1,0.5-2.4,0.8-3.8,0.8c-1.4,0-2.6-0.3-3.7-0.9c-1.1-0.6-2.1-1.4-2.9-2.5c-0.8-1.1-1.4-2.3-1.9-3.7c-0.4-1.4-0.7-3-0.7-4.7V85.2z M780.2,85.6c0,1.2,0.1,2.3,0.4,3.3c0.2,1,0.6,1.9,1.1,2.7c0.5,0.8,1.1,1.4,1.9,1.8c0.8,0.4,1.7,0.7,2.8,0.7c0.7,0,1.3-0.1,1.9-0.2c0.6-0.2,1.1-0.4,1.5-0.7s0.9-0.7,1.2-1.1c0.4-0.4,0.7-0.9,0.9-1.4V80c-0.3-0.5-0.6-0.9-0.9-1.3c-0.3-0.4-0.7-0.7-1.2-1c-0.5-0.3-1-0.5-1.5-0.7c-0.6-0.2-1.2-0.2-1.9-0.2c-1.1,0-2,0.2-2.8,0.7c-0.8,0.5-1.4,1.1-1.9,1.8c-0.5,0.8-0.9,1.7-1.1,2.7c-0.2,1-0.4,2.1-0.4,3.3V85.6z\"/><path class=\"st1\" d=\"M811.6,97.4c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5v-0.9c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8c0.9-1,2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8H805c0,1.1,0.2,2.1,0.5,3c0.3,0.9,0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6c0.8,0.4,1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4c-0.7,0.4-1.5,0.8-2.4,1C813.8,97.3,812.8,97.4,811.6,97.4z M811.1,76.6c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9h11.6v-0.3c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5C813,76.8,812.2,76.6,811.1,76.6z\"/><path class=\"st1\" d=\"M829,73.7l0.1,2.6c0.8-0.9,1.8-1.7,2.9-2.2c1.1-0.5,2.5-0.8,4-0.8c1.5,0,2.8,0.3,4,0.9c1.2,0.6,2,1.5,2.7,2.8c0.8-1.1,1.8-2,3-2.7c1.2-0.7,2.7-1,4.4-1c1.2,0,2.3,0.2,3.3,0.5c1,0.3,1.8,0.8,2.4,1.5s1.2,1.6,1.5,2.6c0.3,1.1,0.5,2.3,0.5,3.8V97h-4V81.7c0-1-0.1-1.8-0.4-2.4s-0.6-1.2-1-1.5s-1-0.7-1.6-0.8c-0.6-0.2-1.3-0.2-2-0.2c-0.8,0-1.5,0.1-2.2,0.4c-0.6,0.3-1.2,0.6-1.6,1c-0.5,0.4-0.8,1-1.1,1.5c-0.3,0.6-0.4,1.2-0.5,1.9V97h-4V81.7c0-0.9-0.1-1.7-0.4-2.3c-0.2-0.6-0.6-1.2-1-1.6c-0.4-0.4-0.9-0.7-1.6-0.9c-0.6-0.2-1.3-0.3-2.1-0.3c-1.4,0-2.6,0.3-3.4,0.9c-0.9,0.6-1.5,1.4-1.9,2.4v17h-4V73.7H829z\"/><path class=\"st1\" d=\"M891.1,86.5h4.3v3.2h-4.3V97h-4v-7.3h-14.2v-2.3l14-21.7h4.2V86.5z M877.4,86.5h9.7V71.1l-0.5,0.9L877.4,86.5z\"/></g></g><g id=\"modem1\" class=\"jsModem1\"><path class=\"st0\" d=\"M922,306.2H676.5c-2.2,0-4-1.8-4-4v-123c0-2.2,1.8-4,4-4H922c2.2,0,4,1.8,4,4v123C926,304.4,924.2,306.2,922,306.2z\"/><g><path class=\"st1\" d=\"M719.6,226.4l10.2,25.5l10.2-25.5h5.3v31.3h-4.1v-12.2l0.4-13.1l-10.3,25.3h-3.2L718,232.4l0.4,13.1v12.2h-4.1v-31.3H719.6z\"/><path class=\"st1\" d=\"M751,245.8c0-1.7,0.2-3.3,0.7-4.7s1.2-2.7,2.1-3.7c0.9-1.1,2-1.9,3.3-2.5c1.3-0.6,2.8-0.9,4.4-0.9c1.6,0,3.1,0.3,4.4,0.9s2.4,1.4,3.3,2.5c0.9,1.1,1.6,2.3,2.1,3.7c0.5,1.4,0.7,3,0.7,4.7v0.5c0,1.7-0.2,3.3-0.7,4.7c-0.5,1.4-1.2,2.7-2.1,3.7c-0.9,1.1-2,1.9-3.3,2.5c-1.3,0.6-2.8,0.9-4.4,0.9s-3.1-0.3-4.4-0.9c-1.3-0.6-2.4-1.4-3.3-2.5c-0.9-1.1-1.6-2.3-2.1-3.7s-0.7-3-0.7-4.7V245.8z M755,246.3c0,1.2,0.1,2.3,0.4,3.3c0.3,1,0.7,1.9,1.2,2.7c0.6,0.8,1.2,1.4,2.1,1.9c0.8,0.5,1.8,0.7,2.9,0.7c1.1,0,2-0.2,2.9-0.7c0.8-0.5,1.5-1.1,2.1-1.9c0.5-0.8,1-1.7,1.2-2.7s0.4-2.1,0.4-3.3v-0.5c0-1.1-0.1-2.2-0.4-3.3c-0.3-1-0.7-1.9-1.2-2.7c-0.6-0.8-1.2-1.4-2.1-1.9c-0.8-0.5-1.8-0.7-2.9-0.7c-1.1,0-2,0.2-2.9,0.7c-0.8,0.5-1.5,1.1-2.1,1.9c-0.6,0.8-1,1.7-1.2,2.7c-0.3,1-0.4,2.1-0.4,3.3V246.3z\"/><path class=\"st1\" d=\"M776.2,245.9c0-1.8,0.2-3.4,0.7-4.8c0.4-1.5,1.1-2.7,1.9-3.7c0.8-1,1.8-1.8,2.9-2.4c1.1-0.6,2.4-0.9,3.8-0.9c1.4,0,2.7,0.2,3.7,0.7c1.1,0.5,2,1.2,2.8,2.1v-12.1h4v33h-3.7l-0.2-2.5c-0.8,0.9-1.7,1.7-2.8,2.2c-1.1,0.5-2.4,0.8-3.8,0.8c-1.4,0-2.6-0.3-3.7-0.9c-1.1-0.6-2.1-1.4-2.9-2.5c-0.8-1.1-1.4-2.3-1.9-3.7c-0.4-1.4-0.7-3-0.7-4.7V245.9z M780.2,246.3c0,1.2,0.1,2.3,0.4,3.3c0.2,1,0.6,1.9,1.1,2.7c0.5,0.8,1.1,1.4,1.9,1.8c0.8,0.4,1.7,0.7,2.8,0.7c0.7,0,1.3-0.1,1.9-0.2c0.6-0.2,1.1-0.4,1.5-0.7s0.9-0.7,1.2-1.1c0.4-0.4,0.7-0.9,0.9-1.4v-10.7c-0.3-0.5-0.6-0.9-0.9-1.3c-0.3-0.4-0.7-0.7-1.2-1c-0.5-0.3-1-0.5-1.5-0.7c-0.6-0.2-1.2-0.2-1.9-0.2c-1.1,0-2,0.2-2.8,0.7c-0.8,0.5-1.4,1.1-1.9,1.8c-0.5,0.8-0.9,1.7-1.1,2.7c-0.2,1-0.4,2.1-0.4,3.3V246.3z\"/><path class=\"st1\" d=\"M811.6,258.1c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5V246c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8c0.9-1,2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8H805c0,1.1,0.2,2.1,0.5,3c0.3,0.9,0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6c0.8,0.4,1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4c-0.7,0.4-1.5,0.8-2.4,1C813.8,258,812.8,258.1,811.6,258.1z M811.1,237.3c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9h11.6v-0.3c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5C813,237.4,812.2,237.3,811.1,237.3z\"/><path class=\"st1\" d=\"M829,234.4l0.1,2.6c0.8-0.9,1.8-1.7,2.9-2.2c1.1-0.5,2.5-0.8,4-0.8c1.5,0,2.8,0.3,4,0.9c1.2,0.6,2,1.5,2.7,2.8c0.8-1.1,1.8-2,3-2.7c1.2-0.7,2.7-1,4.4-1c1.2,0,2.3,0.2,3.3,0.5c1,0.3,1.8,0.8,2.4,1.5s1.2,1.6,1.5,2.6c0.3,1.1,0.5,2.3,0.5,3.8v15.3h-4v-15.3c0-1-0.1-1.8-0.4-2.4s-0.6-1.2-1-1.5s-1-0.7-1.6-0.8c-0.6-0.2-1.3-0.2-2-0.2c-0.8,0-1.5,0.1-2.2,0.4c-0.6,0.3-1.2,0.6-1.6,1c-0.5,0.4-0.8,1-1.1,1.5c-0.3,0.6-0.4,1.2-0.5,1.9v15.4h-4v-15.3c0-0.9-0.1-1.7-0.4-2.3c-0.2-0.6-0.6-1.2-1-1.6c-0.4-0.4-0.9-0.7-1.6-0.9c-0.6-0.2-1.3-0.3-2.1-0.3c-1.4,0-2.6,0.3-3.4,0.9c-0.9,0.6-1.5,1.4-1.9,2.4v17h-4v-23.2H829z\"/><path class=\"st1\" d=\"M887.4,257.7h-4v-26.5l-8,2.9v-3.6l11.4-4.3h0.6V257.7z\"/></g></g><g id=\"modem2\" class=\"jsModem2\"><path class=\"st0\" d=\"M922,463.2H676.5c-2.2,0-4-1.8-4-4v-123c0-2.2,1.8-4,4-4H922c2.2,0,4,1.8,4,4v123C926,461.4,924.2,463.2,922,463.2z\"/><g><path class=\"st1\" d=\"M719.6,380.4l10.2,25.5l10.2-25.5h5.3v31.3h-4.1v-12.2l0.4-13.1l-10.3,25.3h-3.2L718,386.4l0.4,13.1v12.2h-4.1v-31.3H719.6z\"/><path class=\"st1\" d=\"M751,399.8c0-1.7,0.2-3.3,0.7-4.7s1.2-2.7,2.1-3.7c0.9-1.1,2-1.9,3.3-2.5c1.3-0.6,2.8-0.9,4.4-0.9c1.6,0,3.1,0.3,4.4,0.9s2.4,1.4,3.3,2.5c0.9,1.1,1.6,2.3,2.1,3.7c0.5,1.4,0.7,3,0.7,4.7v0.5c0,1.7-0.2,3.3-0.7,4.7c-0.5,1.4-1.2,2.7-2.1,3.7c-0.9,1.1-2,1.9-3.3,2.5c-1.3,0.6-2.8,0.9-4.4,0.9s-3.1-0.3-4.4-0.9c-1.3-0.6-2.4-1.4-3.3-2.5c-0.9-1.1-1.6-2.3-2.1-3.7s-0.7-3-0.7-4.7V399.8z M755,400.3c0,1.2,0.1,2.3,0.4,3.3c0.3,1,0.7,1.9,1.2,2.7c0.6,0.8,1.2,1.4,2.1,1.9c0.8,0.5,1.8,0.7,2.9,0.7c1.1,0,2-0.2,2.9-0.7c0.8-0.5,1.5-1.1,2.1-1.9c0.5-0.8,1-1.7,1.2-2.7s0.4-2.1,0.4-3.3v-0.5c0-1.1-0.1-2.2-0.4-3.3c-0.3-1-0.7-1.9-1.2-2.7c-0.6-0.8-1.2-1.4-2.1-1.9c-0.8-0.5-1.8-0.7-2.9-0.7c-1.1,0-2,0.2-2.9,0.7c-0.8,0.5-1.5,1.1-2.1,1.9c-0.6,0.8-1,1.7-1.2,2.7c-0.3,1-0.4,2.1-0.4,3.3V400.3z\"/><path class=\"st1\" d=\"M776.2,399.8c0-1.8,0.2-3.4,0.7-4.8c0.4-1.5,1.1-2.7,1.9-3.7c0.8-1,1.8-1.8,2.9-2.4c1.1-0.6,2.4-0.9,3.8-0.9c1.4,0,2.7,0.2,3.7,0.7c1.1,0.5,2,1.2,2.8,2.1v-12.1h4v33h-3.7l-0.2-2.5c-0.8,0.9-1.7,1.7-2.8,2.2c-1.1,0.5-2.4,0.8-3.8,0.8c-1.4,0-2.6-0.3-3.7-0.9c-1.1-0.6-2.1-1.4-2.9-2.5c-0.8-1.1-1.4-2.3-1.9-3.7c-0.4-1.4-0.7-3-0.7-4.7V399.8z M780.2,400.3c0,1.2,0.1,2.3,0.4,3.3c0.2,1,0.6,1.9,1.1,2.7c0.5,0.8,1.1,1.4,1.9,1.8c0.8,0.4,1.7,0.7,2.8,0.7c0.7,0,1.3-0.1,1.9-0.2c0.6-0.2,1.1-0.4,1.5-0.7s0.9-0.7,1.2-1.1c0.4-0.4,0.7-0.9,0.9-1.4v-10.7c-0.3-0.5-0.6-0.9-0.9-1.3c-0.3-0.4-0.7-0.7-1.2-1c-0.5-0.3-1-0.5-1.5-0.7c-0.6-0.2-1.2-0.2-1.9-0.2c-1.1,0-2,0.2-2.8,0.7c-0.8,0.5-1.4,1.1-1.9,1.8c-0.5,0.8-0.9,1.7-1.1,2.7c-0.2,1-0.4,2.1-0.4,3.3V400.3z\"/><path class=\"st1\" d=\"M811.6,412.1c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5v-0.9c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8c0.9-1,2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8H805c0,1.1,0.2,2.1,0.5,3c0.3,0.9,0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6c0.8,0.4,1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4c-0.7,0.4-1.5,0.8-2.4,1C813.8,412,812.8,412.1,811.6,412.1z M811.1,391.2c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9h11.6v-0.3c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5C813,391.4,812.2,391.2,811.1,391.2z\"/><path class=\"st1\" d=\"M829,388.4l0.1,2.6c0.8-0.9,1.8-1.7,2.9-2.2c1.1-0.5,2.5-0.8,4-0.8c1.5,0,2.8,0.3,4,0.9c1.2,0.6,2,1.5,2.7,2.8c0.8-1.1,1.8-2,3-2.7c1.2-0.7,2.7-1,4.4-1c1.2,0,2.3,0.2,3.3,0.5c1,0.3,1.8,0.8,2.4,1.5s1.2,1.6,1.5,2.6c0.3,1.1,0.5,2.3,0.5,3.8v15.3h-4v-15.3c0-1-0.1-1.8-0.4-2.4s-0.6-1.2-1-1.5s-1-0.7-1.6-0.8c-0.6-0.2-1.3-0.2-2-0.2c-0.8,0-1.5,0.1-2.2,0.4c-0.6,0.3-1.2,0.6-1.6,1c-0.5,0.4-0.8,1-1.1,1.5c-0.3,0.6-0.4,1.2-0.5,1.9v15.4h-4v-15.3c0-0.9-0.1-1.7-0.4-2.3c-0.2-0.6-0.6-1.2-1-1.6c-0.4-0.4-0.9-0.7-1.6-0.9c-0.6-0.2-1.3-0.3-2.1-0.3c-1.4,0-2.6,0.3-3.4,0.9c-0.9,0.6-1.5,1.4-1.9,2.4v17h-4v-23.2H829z\"/><path class=\"st1\" d=\"M894.8,411.7h-20.5v-2.9l10.2-11.4c0.9-1,1.7-2,2.4-2.8c0.6-0.8,1.1-1.5,1.5-2.2s0.6-1.3,0.8-1.9c0.1-0.6,0.2-1.2,0.2-1.8c0-0.8-0.1-1.5-0.4-2.2c-0.2-0.7-0.6-1.3-1.1-1.8c-0.5-0.5-1-0.9-1.7-1.2c-0.7-0.3-1.4-0.4-2.3-0.4c-1.1,0-2,0.2-2.8,0.5c-0.8,0.3-1.4,0.8-1.9,1.3s-0.9,1.2-1.2,2c-0.3,0.8-0.4,1.6-0.4,2.6h-4c0-1.3,0.2-2.6,0.7-3.7c0.4-1.2,1.1-2.2,1.9-3.1c0.9-0.9,1.9-1.6,3.2-2.1c1.3-0.5,2.8-0.8,4.4-0.8c1.5,0,2.8,0.2,4,0.6c1.2,0.4,2.2,1,3,1.7c0.8,0.7,1.4,1.6,1.9,2.7s0.6,2.2,0.6,3.4c0,0.9-0.2,1.8-0.5,2.8c-0.3,0.9-0.7,1.9-1.3,2.8c-0.5,0.9-1.2,1.8-1.9,2.8c-0.7,0.9-1.5,1.8-2.3,2.7l-8.4,9.1h15.7V411.7z\"/></g></g><g id=\"modem3\" class=\"jsModem3\"><path class=\"st0\" d=\"M922,619.9H676.5c-2.2,0-4-1.8-4-4v-123c0-2.2,1.8-4,4-4H922c2.2,0,4,1.8,4,4v123C926,618.1,924.2,619.9,922,619.9z\"/><g><path class=\"st1\" d=\"M719.6,537.1l10.2,25.5l10.2-25.5h5.3v31.3h-4.1v-12.2l0.4-13.1l-10.3,25.3h-3.2L718,543.1l0.4,13.1v12.2h-4.1v-31.3H719.6z\"/><path class=\"st1\" d=\"M751,556.6c0-1.7,0.2-3.3,0.7-4.7s1.2-2.7,2.1-3.7c0.9-1.1,2-1.9,3.3-2.5c1.3-0.6,2.8-0.9,4.4-0.9c1.6,0,3.1,0.3,4.4,0.9s2.4,1.4,3.3,2.5c0.9,1.1,1.6,2.3,2.1,3.7c0.5,1.4,0.7,3,0.7,4.7v0.5c0,1.7-0.2,3.3-0.7,4.7c-0.5,1.4-1.2,2.7-2.1,3.7c-0.9,1.1-2,1.9-3.3,2.5c-1.3,0.6-2.8,0.9-4.4,0.9s-3.1-0.3-4.4-0.9c-1.3-0.6-2.4-1.4-3.3-2.5c-0.9-1.1-1.6-2.3-2.1-3.7s-0.7-3-0.7-4.7V556.6z M755,557c0,1.2,0.1,2.3,0.4,3.3c0.3,1,0.7,1.9,1.2,2.7c0.6,0.8,1.2,1.4,2.1,1.9c0.8,0.5,1.8,0.7,2.9,0.7c1.1,0,2-0.2,2.9-0.7c0.8-0.5,1.5-1.1,2.1-1.9c0.5-0.8,1-1.7,1.2-2.7s0.4-2.1,0.4-3.3v-0.5c0-1.1-0.1-2.2-0.4-3.3s-0.7-1.9-1.2-2.7c-0.6-0.8-1.2-1.4-2.1-1.9c-0.8-0.5-1.8-0.7-2.9-0.7c-1.1,0-2,0.2-2.9,0.7s-1.5,1.1-2.1,1.9c-0.6,0.8-1,1.7-1.2,2.7c-0.3,1-0.4,2.1-0.4,3.3V557z\"/><path class=\"st1\" d=\"M776.2,556.6c0-1.8,0.2-3.4,0.7-4.8c0.4-1.5,1.1-2.7,1.9-3.7c0.8-1,1.8-1.8,2.9-2.4c1.1-0.6,2.4-0.9,3.8-0.9c1.4,0,2.7,0.2,3.7,0.7c1.1,0.5,2,1.2,2.8,2.1v-12.1h4v33h-3.7l-0.2-2.5c-0.8,0.9-1.7,1.7-2.8,2.2c-1.1,0.5-2.4,0.8-3.8,0.8c-1.4,0-2.6-0.3-3.7-0.9c-1.1-0.6-2.1-1.4-2.9-2.5c-0.8-1.1-1.4-2.3-1.9-3.7c-0.4-1.4-0.7-3-0.7-4.7V556.6z M780.2,557c0,1.2,0.1,2.3,0.4,3.3s0.6,1.9,1.1,2.7c0.5,0.8,1.1,1.4,1.9,1.8s1.7,0.7,2.8,0.7c0.7,0,1.3-0.1,1.9-0.2s1.1-0.4,1.5-0.7s0.9-0.7,1.2-1.1c0.4-0.4,0.7-0.9,0.9-1.4v-10.7c-0.3-0.5-0.6-0.9-0.9-1.3s-0.7-0.7-1.2-1s-1-0.5-1.5-0.7s-1.2-0.2-1.9-0.2c-1.1,0-2,0.2-2.8,0.7c-0.8,0.5-1.4,1.1-1.9,1.8c-0.5,0.8-0.9,1.7-1.1,2.7s-0.4,2.1-0.4,3.3V557z\"/><path class=\"st1\" d=\"M811.6,568.8c-1.6,0-3.1-0.3-4.4-0.8s-2.4-1.3-3.4-2.3c-0.9-1-1.6-2.2-2.1-3.6c-0.5-1.4-0.8-2.9-0.8-4.5v-0.9c0-1.9,0.3-3.6,0.8-5.1c0.6-1.5,1.3-2.7,2.3-3.8s2-1.8,3.2-2.3c1.2-0.5,2.5-0.8,3.8-0.8c1.7,0,3.1,0.3,4.3,0.9s2.2,1.4,3,2.4c0.8,1,1.4,2.2,1.7,3.6c0.4,1.4,0.6,2.9,0.6,4.5v1.8H805c0,1.1,0.2,2.1,0.5,3s0.8,1.7,1.4,2.4c0.6,0.7,1.3,1.2,2.1,1.6s1.8,0.6,2.8,0.6c1.4,0,2.6-0.3,3.6-0.9c1-0.6,1.8-1.3,2.6-2.3l2.4,1.9c-0.4,0.6-0.8,1.1-1.4,1.7c-0.5,0.5-1.1,1-1.9,1.4s-1.5,0.8-2.4,1C813.8,568.7,812.8,568.8,811.6,568.8z M811.1,548c-0.8,0-1.5,0.1-2.2,0.4c-0.7,0.3-1.3,0.7-1.8,1.3c-0.5,0.6-1,1.3-1.3,2.1c-0.4,0.8-0.6,1.8-0.7,2.9h11.6v-0.3c0-0.8-0.2-1.5-0.4-2.3c-0.2-0.8-0.5-1.4-1-2c-0.4-0.6-1-1.1-1.7-1.5S812.2,548,811.1,548z\"/><path class=\"st1\" d=\"M829,545.1l0.1,2.6c0.8-0.9,1.8-1.7,2.9-2.2s2.5-0.8,4-0.8c1.5,0,2.8,0.3,4,0.9c1.2,0.6,2,1.5,2.7,2.8c0.8-1.1,1.8-2,3-2.7c1.2-0.7,2.7-1,4.4-1c1.2,0,2.3,0.2,3.3,0.5c1,0.3,1.8,0.8,2.4,1.5s1.2,1.6,1.5,2.6s0.5,2.3,0.5,3.8v15.3h-4v-15.3c0-1-0.1-1.8-0.4-2.4s-0.6-1.2-1-1.5s-1-0.7-1.6-0.8c-0.6-0.2-1.3-0.2-2-0.2c-0.8,0-1.5,0.1-2.2,0.4c-0.6,0.3-1.2,0.6-1.6,1s-0.8,1-1.1,1.5c-0.3,0.6-0.4,1.2-0.5,1.9v15.4h-4v-15.3c0-0.9-0.1-1.7-0.4-2.3s-0.6-1.2-1-1.6s-0.9-0.7-1.6-0.9c-0.6-0.2-1.3-0.3-2.1-0.3c-1.4,0-2.6,0.3-3.4,0.9s-1.5,1.4-1.9,2.4v17h-4v-23.2H829z\"/><path class=\"st1\" d=\"M880.1,550.8h2.8c1,0,1.9-0.1,2.7-0.4s1.4-0.6,1.9-1.1s0.9-1,1.2-1.7s0.4-1.4,0.4-2.1c0-1.8-0.5-3.2-1.4-4.1s-2.3-1.4-4.1-1.4c-0.8,0-1.6,0.1-2.3,0.4c-0.7,0.3-1.3,0.6-1.8,1.1s-0.9,1-1.1,1.7c-0.3,0.7-0.4,1.4-0.4,2.2h-4c0-1.2,0.2-2.3,0.7-3.4c0.5-1,1.1-2,2-2.7c0.8-0.8,1.9-1.4,3-1.8s2.5-0.7,3.9-0.7c1.4,0,2.7,0.2,3.9,0.6s2.2,0.9,3,1.7c0.8,0.7,1.5,1.7,1.9,2.8c0.5,1.1,0.7,2.4,0.7,3.8c0,0.6-0.1,1.2-0.3,1.8s-0.5,1.3-0.9,1.9c-0.4,0.6-0.9,1.2-1.5,1.7s-1.4,1-2.2,1.3c1,0.3,1.9,0.8,2.6,1.3c0.7,0.5,1.2,1.1,1.7,1.8c0.4,0.7,0.7,1.4,0.9,2.1s0.3,1.4,0.3,2.1c0,1.5-0.3,2.8-0.8,3.9c-0.5,1.1-1.2,2.1-2.1,2.9c-0.9,0.8-1.9,1.4-3.1,1.8s-2.5,0.6-3.9,0.6c-1.4,0-2.6-0.2-3.8-0.6c-1.2-0.4-2.3-0.9-3.2-1.7s-1.6-1.6-2.1-2.7c-0.5-1.1-0.8-2.3-0.8-3.7h4c0,0.8,0.1,1.6,0.4,2.2c0.3,0.7,0.7,1.2,1.2,1.7s1.1,0.8,1.9,1.1s1.6,0.4,2.5,0.4c0.9,0,1.7-0.1,2.5-0.4s1.4-0.6,1.9-1.1s0.9-1.1,1.2-1.8c0.3-0.7,0.4-1.6,0.4-2.6s-0.2-1.8-0.5-2.5c-0.3-0.7-0.8-1.3-1.3-1.8s-1.3-0.8-2.1-1s-1.7-0.3-2.8-0.3h-2.8V550.8z\"/></g></g></g>");
        return window.otb;
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

    /**
     * Get all custommer services
     * @param {JQuery}   jqDest   Select field to fill
     * @param {Function} callback Callback function invoked when done
     */
    window.otb.getServices = function (jqDest, serviceList/*, callback*/) {
        var callback = otb.getCallback(arguments);
        if (!otb.isJquery(jqDest)) {
            return callback("Internal error");
        }
        var container = $(jqDest.get(0));

        var jqElt;
        if (serviceList.length > 1) {
            serviceList.sort(function (a, b) {
                if (a.device && !b.device) {
                    return 1;
                }
                if (!a.device && b.device) {
                    return -1;
                }
                var strA = a.customerDescription || a.serviceName;
                var strB = b.customerDescription || b.serviceName;
                if (strA > strB) {
                    return 1;
                }
                if (strA < strB) {
                    return -1;
                }
                if (strA == strB) {
                    return 0;
                }
            });
            jqElt = container.find("select#serviceList");
            if (jqElt.length) {
                jqElt.children().remove();
            } else {
                jqElt = $("<select id=\"serviceList\" class=\"custom-select form-control\"></select>");
            }
            container.append(jqElt);
            var selection = $("<input type=\"hidden\" name=\"serviceSelected\" value=\"" + serviceList[0].serviceName + "\">");
            container.append(selection);
            jqElt.change(function () {
                selection.val($(this).find("option:selected").val());
            });
            serviceList.forEach(function (service) {
                var device = service.device && service.device.deviceId ? ["(", service.device.deviceId, ")"].join("") : "";
                jqElt.append("<option name=\"serviceId\" value=\"" + service.serviceName + "\">" + (service.customerDescription || service.serviceName) + " " + device + "</option>");
            });
            $("label.serviceList").show();
            $("p.uniqueService").hide();
            $("a.noService").hide();
            window.otb.getRegisterService = function () {
                var selection = jqElt.val();
                var result;
                serviceList.forEach(function (service) {
                    if (service.serviceName === selection) {
                        result = service;
                    }
                });
                return result;
            };
            callback(null);
        } else if (serviceList.length === 1) {
            container.append("<input type=\"hidden\" name=\"serviceSelected\" value=\"" + serviceList[0].serviceName + "\">");
            $("p.uniqueService").find(".serviceName").text(serviceList[0].serviceName);
            $("p.uniqueService").find(".customerDescription").text(serviceList[0].customerDescription || "");
            $("p.uniqueService").show();
            $("label.serviceList").hide();
            $("a.noService").hide();
            window.otb.getRegisterService = function () {
                return serviceList[0];
            };
            callback(null);
        } else {
            $("div.noService").show();
            $("label.serviceList").hide();
            $("p.uniqueService").hide();
            callback("no-service");
        }

    };

    /**
     * Set the submit function
     * @param {JQuery}   jqForm   form
     * @param {Function} callback Callback function to execute on submit
     */
    window.otb.attachSubmit = function (jqForm /*, callback*/) {
        var callback = otb.getCallback(arguments);
        if (!otb.isJquery(jqForm)) {
            return callback();
        }
        var form = jqForm.get(0);

        var processForm = function (e) {
            if (e.preventDefault) {
                e.preventDefault();
            }
            callback(form);
            return false;
        };

        if (form.attachEvent) {
            form.attachEvent("submit", processForm);
        } else {
            form.addEventListener("submit", processForm);
        }
    };

    /**
     * Check if a device is link to a service
     * @param {Array}  serviceList List of services
     * @param {String} deviceId    Device identifier
     * @return null|service struct
     */
    window.otb.checkLinkedDevice = function (serviceList, deviceId) {
        var foundService = null;
        serviceList.forEach(function (elt) {
            if (elt.device && elt.device.deviceId === deviceId) {
                foundService = elt;
            }
        });
        return foundService;
    };

})();