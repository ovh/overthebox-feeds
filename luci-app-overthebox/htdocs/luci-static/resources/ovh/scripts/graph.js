function bandwidth_label(bytes, br)
{
    var uby = 'kB/s';
    var kby = (bytes / 1024);

    if (kby >= 1024)
    {
        uby = 'MB/s';
        kby = kby / 1024;
    }

    var ubi = 'kbit/s';
    var kbi = (bytes * 8 / 1024);

    if (kbi >= 1024)
    {
        ubi = 'Mbit/s';
        kbi = kbi / 1024;
    }

    return String.format("<span class=\"big-unit\">%f %s</span>%s<span class=\"small-unit\">(%f %s)</span>",
        kbi.toFixed(2), ubi,
        br ? '<br />' : ' ',
        kby.toFixed(2), uby
    );
}

function createStatsFooter(name, itf, color, label){
    var table = document.getElementById(name + '_stats');
    var tr = table.insertRow();
    tr.setAttribute('id', itf + '_' + name);

    // Create cells of the table
    var itflabel = tr.insertCell(0);

    // Crete itf legend
    var strong = document.createElement('strong');
    strong.appendChild(document.createTextNode(label ? label : itf));
    strong.setAttribute('style', 'border-bottom:2px solid ' + color);
    itflabel.appendChild(strong);

    // Create label for stats
    insertDescriptionValueElements(tr, 1, itf + '_' + name + '_cur', "Current:");
    insertDescriptionValueElements(tr, 2, itf + '_' + name + '_avg', "Average:");
    insertDescriptionValueElements(tr, 3, itf + '_' + name + '_peak', "Peak:");
}

function insertDescriptionValueElements(parent, index, id, descriptionLabel){
    var cell = parent.insertCell(index);
    var spanDescription = document.createElement("span");
    spanDescription.className = "description";
    spanDescription.innerHTML = descriptionLabel;
    cell.appendChild(spanDescription);

    var spanValue = document.createElement("span");
    spanValue.className = "value"
    spanValue.setAttribute('id', id);
    cell.appendChild(spanValue);
}

function insertXAxisValue(parent, content, top, left){
    if(parent !== undefined)
    {
        var span = document.createElement("span");
        span.className = "description";
        span.innerHTML = content
        span.style.position = "absolute";
        span.style.top = top + "px";
        span.style.left = left + "px";

        parent.append(span);
    }
}
