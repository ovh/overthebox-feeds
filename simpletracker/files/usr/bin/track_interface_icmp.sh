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


# Check arguments
while getopts "i:t:h:" opt; do
	case $opt in
		t) timeout="$OPTARG";;
		h) host="$OPTARG";;
		i) interface="$OPTARG";;
		*) usage;;
	esac
done

# Ping
response=$( ping -c 1 -I "$interface" -W "$timeout" "$host" 2>&1)

# Script call
if [ $? != 0 ]; then
	/usr/bin/scripts/icmp_infos.sh -i "$interface" -h "$host" -l "-1" &
	log FAIL ICMP: "$interface" to "$host"
else
	result=$( echo "$response" | cut -d '/' -s -f 5)
	/usr/bin/scripts/icmp_infos.sh -i "$interface" -h "$host" -l "$result" &
	log ICMP: "$interface" to "$host"
fi

exit 0

