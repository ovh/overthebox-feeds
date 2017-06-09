#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

###############################################
# This script checks interface status
# Result is sent to interface_status script
# Result can be either UP or DOWN
##############################################

. /lib/functions/network.sh

log() {
	logger -p user.notice -t "simpletracker" "$@"
}


# Check arguments
while getopts "i:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		*) echo fail;;
	esac
done

# Ubus call to retrieve interface status
network_flush_cache
network_is_up "$interface" && result=true || result=false

# Script call
if [ "$result" = false ];then
	/usr/bin/scripts/interface_status.sh -i "$interface" -s DOWN
	log FAIL STATE: "$interface" is down
elif [ "$result" = true ]; then
	/usr/bin/scripts/interface_status.sh -i "$interface" -s UP
	log STATE: "$interface" is up
else
	# Should never be executed
	log FAIL STATE: "$interface" is undefined
	exit 1
fi

