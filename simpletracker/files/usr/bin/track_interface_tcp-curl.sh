#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

log() {
	logger -p user.notice -t "simpletracker" "$@"
}

usage() {
	printf "Usage : %S: [-i INTERFACE] [-h HOST] [-t TIMEOUT]\n" "$0"
	exit 1
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

# Script call
response="$( curl -s --interface "$interface" -m "$timeout" "$host" )"
if [ -n "$response" ] ; then
	/usr/bin/scripts/curl_infos.sh -i "$interface" -h "$host" -p "$response" &
	log CURL: "$interface" to "$host"
	exit 0
fi
/usr/bin/scripts/curl_infos.sh -i "$interface" -h "$host" -p "-1" &
log FAIL CURL: "$interface" to "$host"
exit 0
