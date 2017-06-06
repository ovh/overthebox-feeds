#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

###############################################
# This script checks interface status
# Result is sent to interface_status script
# Result can be either UP or DOWN
##############################################

# Check arguments
while getopts "i:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		*) echo fail;;
	esac
done

# Ubus call to retrieve interface status
result="$( ubus -S call network.interface."$interface" status | jsonfilter -e "$.up" )"

# Script call
if [ "$result" = false ];then
	/usr/bin/scripts/interface_status.sh -i "$interface" -s DOWN
elif [ "$result" = true ]; then
	/usr/bin/scripts/interface_status.sh -i "$interface" -s UP
else
	# Should never be executed
	echo "Dafuk ?"
	exit 1
fi

