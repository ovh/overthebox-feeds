'use strict';

// Tool to create SVG elements
// Those are XML not HTML balises

return L.Class.extend({
    createBackground: function (id) {
        let svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttributeNS(null, 'width', '100%');
        svg.setAttributeNS(null, 'height', '100%');
        svg.setAttributeNS(null, 'version', '1.1');

        // Append labels lines
        svg.appendChild(this.createLineElem('0', '25%', '100%', '25%'))
        svg.appendChild(this.createLabelElem('20', '24%', id + '_label_75'))
        svg.appendChild(this.createLineElem('0', '50%', '100%', '50%'))
        svg.appendChild(this.createLabelElem('20', '49%', id + '_label_50'))
        svg.appendChild(this.createLineElem('0', '75%', '100%', '75%'))
        svg.appendChild(this.createLabelElem('20', '74%', id + '_label_25'))

        // Add peak label
        svg.appendChild(this.createLabelElem('20', '12%', id + '_label_peak'))
        svg.appendChild(this.createLabelElem('20', '18%', id + '_label_avg'))
        return svg;
    },

    createLabelElem: function (x_pos, y_pos, id) {
        let text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('id', id);
        text.setAttribute('x', x_pos);
        text.setAttribute('y', y_pos);
        text.setAttribute('class', 'otb-graph-label');
        text.appendChild(document.createTextNode(''));

        return text;
    },

    // Create a SVG polyline element
    createPolyLineElem: function (id, color, opacity) {
        let line = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
        line.setAttributeNS(null, 'id', id);
        line.setAttributeNS(null, 'style', 'fill:' + color + ';fill-opacity:' + opacity + ';');
        return line;
    },

    // Create a SVG text element
    createTextElem: function (x_pos, y_pos, label) {
        let text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('x', x_pos);
        text.setAttribute('y', y_pos);
        text.setAttribute('class', 'otb-graph-text');
        text.appendChild(document.createTextNode(label));

        return text;
    },

    // Create a SVG line element
    createLineElem: function (x1_pos, y1_pos, x2_pos, y2_pos) {
        let line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        line.setAttribute('x1', x1_pos);
        line.setAttribute('y1', y1_pos);
        line.setAttribute('x2', x2_pos);
        line.setAttribute('y2', y2_pos);
        line.setAttribute('class', 'otb-graph-line');

        return line;
    }
});

