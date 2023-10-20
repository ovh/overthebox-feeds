'use strict';

return L.Class.extend({
	stringToColour: function (str) {
		if (str == "free1")
			return "BlueViolet";
		if (str == "ovh1")
			return "DeepSkyBlue";
		if (str == "ovh2")
			return "LightGreen";

		if (str == "if1")
			return "PowderBlue";
		if (str == "if2")
			return "PaleGreen";
		if (str == "if3")
			return "YellowGreen";
		if (str == "if4")
			return "SeaGreen";
		if (str == "if5")
			return "SteelBlue";
		if (str == "if6")
			return "SlateBlue";
		if (str == "if7")
			return "PaleTurquoise";
		if (str == "if8")
			return "BlueViolet";

		if (str == "tun0")
			return "DimGrey";
		if (str == "xtun0")
			return "FireBrick";

		// Generate a color folowing the name
		Math.seedrandom(str);
		var rand = Math.random() * Math.pow(255, 3);
		Math.seedrandom(); // don't leave a non-random seed in the generator
		for (var i = 0, color = "#"; i < 3; color += ("00" + ((rand >> i++ * 8) & 0xFF).toString(16)).slice(-2));
		return color;
	},

	// Compute a horizontale scale based on peak data
	computeHscale: function (height, peak) {
		const s = Math.floor(Math.log2(peak)),
			d = Math.pow(2, s - (s % 10)),
			m = peak / d,
			n = (m < 5) ? 2 : ((m < 50) ? 10 : ((m < 500) ? 100 : 1000)),
			p = peak + (n * d) - (peak % (n * d));

		return height / p;
	},

	// Compute hlabel
	computeHlabel: function (height, hscale, factor) {
		return (height / hscale) * factor
	},

	// Scale point base on Hscale
	computeHpoint: function (height, hscale, point) {
		let y = height - Math.floor(point * hscale);
		return isNaN(y) ? height : y;
	}
});
