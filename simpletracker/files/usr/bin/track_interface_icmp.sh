#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

#######################################################################
# This script tries to ping through an interface to a given host.
# The result is then sent to an other script
# The result is either -1 in case of ping failure or latency in ms
#######################################################################

log() {
	logger -p user.notice -t "simpletracker" "$@"
}

# Ping
response=$( ping -c 1 -I "$SIMPLETRACKER_INTERFACE" -W "$SIMPLETRACKER_TIMEOUT" "$SIMPLETRACKER_HOST" 2>&1)

# Script call
if [ $? != 0 ]; then
	/usr/bin/scripts/icmp_infos.sh
	log FAIL ICMP: "$SIMPLETRACKER_INTERFACE" to "$SIMPLETRACKER_HOST"
else
	SIMPLETRACKER_INTERFACE_LATENCY=$( echo "$response" | cut -d '/' -s -f 5)
	export SIMPLETRACKER_INTERFACE_LATENCY
	/usr/bin/scripts/icmp_infos.sh
	log ICMP: "$SIMPLETRACKER_INTERFACE" to "$SIMPLETRACKER_HOST"
fi

exit 0

