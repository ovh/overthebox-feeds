#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

. /lib/functions/network.sh

_extract_pub_ip() {
	echo "$1"
}
_extract_latency() {
	echo "$6"
}

log() {
	logger -p user.notice -t "simpletracker" "$@"
}

# Get interface ip
network_flush_cache
network_get_ipaddrs interface_ip "$SIMPLETRACKER_INTERFACE"

# DNS Request
# Script call
for i in $interface_ip; do
	response="$( dig -b "$i" "$SIMPLETRACKER_DOMAIN" @"$SIMPLETRACKER_HOST" +time="$SIMPLETRACKER_TIMEOUT" +short +identify +tcp )"
	if [ $? = 0 ] ; then
		# shellcheck disable=SC2086
		SIMPLETRACKER_INTERFACE_PUBLIC_IP=$( _extract_pub_ip $response )
		# shellcheck disable=SC2086
		SIMPLETRACKER_INTERFACE_LATENCY=$( _extract_latency $response )
		export SIMPLETRACKER_INTERFACE_PUBLIC_IP
		export SIMPLETRACKER_INTERFACE_LATENCY
		/usr/bin/scripts/dns_infos.sh
		log DNS: "$SIMPLETRACKER_INTERFACE" to "$SIMPLETRACKER_HOST" for "$SIMPLETRACKER_DOMAIN"
		exit 0
	fi
done

SIMPLETRACKER_INTERFACE_PUBLIC_IP="ERROR"
SIMPLETRACKER_INTERFACE_LATENCY="ERROR"
export SIMPLETRACKER_INTERFACE_PUBLIC_IP
export SIMPLETRACKER_INTERFACE_LATENCY
/usr/bin/scripts/dns_infos.sh
log FAIL DNS: "$SIMPLETRACKER_INTERFACE" to "$SIMPLETRACKER_HOST" for "$SIMPLETRACKER_DOMAIN"
