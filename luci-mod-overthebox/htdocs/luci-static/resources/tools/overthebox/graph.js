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

	/* Smoother */
	simple_moving_averager: function (name, period) {
		var nums = {}
		nums[name] = [];
		return function (num) {
			nums[name].push(num);
			if (nums[name].length > period)
				nums[name].splice(0, 1);  // remove the first element of the array
			var sum = 0;
			for (var i in nums[name])
				sum += nums[name][i];
			var n = period;
			if (nums[name].length < period)
				n = nums[name].length;
			return (sum / n);
		}
	}
});