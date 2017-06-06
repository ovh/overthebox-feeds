#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :


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

# Get interface ip
interface_ip="$( ubus -S call network.interface.if1 status | jsonfilter -e "$['ipv4-address'].*.address")"

# DNS Request
# Script call
for i in $interface_ip; do
	response="$( dig -b "$i" "$domain" @"$host" +time="$timeout" +short +identify )"
	if [ $? = 0 ] ; then
		pub_ip=$( _extract_pub_ip $response )
		latency=$( _extract_latency $response )
		/usr/bin/scripts/dns_infos.sh -i "$interface" -h "$host" -d "$domain" -l "$latency" -p "$pub_ip";
		exit 0
	fi
done
	/usr/bin/scripts/dns_infos.sh -i "$interface" -h "$host" -d "$domain" -l "-1" -p "-1";

