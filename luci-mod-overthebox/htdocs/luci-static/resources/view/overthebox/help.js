'use strict';
'require view';

document.querySelector('head').appendChild(E('link', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': L.resource('view/overthebox/css/custom.css')
}));

return view.extend({
    title: _('Help'),

    load: function () {
        return;
    },

    render: function (data) {
        return E('div', { 'class': 'cbi-section' }, [
            E('h1', this.title),
            E('div', { 'class': 'cbi-value-description' }, [
                E('p', _('Need help using your OverTheBox ?')),
                E('ul', { 'class': 'help' }, [
                    E('li', { 'class': 'help' }, [
                        E('span', _('Discover more informations about OverTheBox on') + ' '),
                        E('a', { 'href': 'https://help.ovhcloud.com/csm/fr-documentation-web-cloud-internet-overthebox?id=kb_browse_cat&kb_id=e17b4f25551974502d4c6e78b7421955&kb_category=ba44d955f49801102d4ca4d466a7fdf8', 'target': '_blank' }, _('OVHcloud documentation'))
                    ]),
                    E('li', { 'class': 'help' }, [
                        E('span', _('Discover more informations about OpenWRT and general usage on') + ' '),
                        E('a', { 'href': 'https://openwrt.org/docs/guide-user/start', 'target': '_blank' }, _('OpenWRT documentation')),
                    ]),
                    E('li', { 'class': 'help' }, [
                        E('span', _('Ask your questions to our') + ' '),
                        E('a', { 'href': 'https://community.ovh.com/c/telecom', 'target': '_blank' }, _('OVHcloud community')),
                    ]),
                ]),
            ]),
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
