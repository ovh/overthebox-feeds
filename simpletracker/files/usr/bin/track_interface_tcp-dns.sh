#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

. /lib/functions/network.sh
# Check arguments
while getopts "i:t:h:d:" opt; do
	case $opt in
		t) timeout="$OPTARG";;
		h) host="$OPTARG";;
		i) interface="$OPTARG";;
		d) domain="$OPTARG";;
		*) usage;;
	esac
done

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
network_get_ipaddrs interface_ip "$interface"

# DNS Request
# Script call
for i in $interface_ip; do
	response="$( dig -b "$i" "$domain" @"$host" +time="$timeout" +short +identify +tcp )"
	if [ $? = 0 ] ; then
		# shellcheck disable=SC2086
		pub_ip=$( _extract_pub_ip $response )
		# shellcheck disable=SC2086
		latency=$( _extract_latency $response )
		/usr/bin/scripts/dns_infos.sh -i "$interface" -h "$host" -d "$domain" -l "$latency" -p "$pub_ip" &
		log DNS: "$interface" to "$host" for "$domain"
		exit 0
	fi
done
/usr/bin/scripts/dns_infos.sh -i "$interface" -h "$host" -d "$domain" -l "-1" -p "-1" &
log FAIL DNS: "$interface" to "$host" for "$domain"
