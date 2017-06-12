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

# Retrieve interface state
network_flush_cache
network_is_up "$SIMPLETRACKER_INTERFACE" && SIMPLETRACKER_INTERFACE_STATE="UP" || SIMPLETRACKER_INTERFACE_STATE="DOWN"

# Logging
if [ "$SIMPLETRACKER_INTERFACE_STATE" = "DOWN" ];then
	log FAIL STATE: "$SIMPLETRACKER_INTERFACE" is down
elif [ "$SIMPLETRACKER_INTERFACE_STATE" = "UP" ]; then
	log STATE: "$SIMPLETRACKER_INTERFACE" is up
else
	# Should never be executed
	log FAIL STATE: "$SIMPLETRACKER_INTERFACE" is undefined
	exit 1
fi
export "$SIMPLETRACKER_INTERFACE_STATE"
/usr/bin/scripts/interface_status.sh
