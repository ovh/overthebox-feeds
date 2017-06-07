#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :


#########################################################################################
# This script is the entry point of simpletracker
# It allows you to check an interface connectivity
# Select a method to check your interface
# The result is sent to a script, depending on the chosen method
# This script always check interface state before trying to apply the selected method
#########################################################################################


name=$0
ERROR_CODE='-1'
OK_CODE='0'

# list available tracking methods
_available_methods() {
	echo "icmp" "tcp_dns" "udp-dns" "tcp-curl"
}

usage() {
	printf "Usage : %s: [-m METHOD] [-t TIMEOUT] [-h host] [-d domain] INTERFACE\n" "$name"
	printf "Select a method between :"
	for i in $_available_methods; do
		printf "\t- %s\n" "$i"
	done
	printf "Domain is necessary for dns method only\n"
	exit 1
}

_check_method_argument() {
	for i in $( _available_methods ); do
		[ "$i" = "$method" ] && echo "$OK_CODE"
	done
	echo "$ERROR_CODE"
}

_dispatch() {
	case "$method" in
		icmp)
			/usr/bin/track_interface_icmp.sh -i "$interface" -h "$host" -t "$timeout"
			exit 0;;
		udp-dns)
			/usr/bin/track_interface_udp-dns.sh -i "$interface" -h "$host" -t "$timeout" -d "$domain"
			exit 0;;
		tcp-dns)
			/usr/bin/track_interface_tcp-dns.sh -i "$interface" -h "$host" -t "$timeout" -d "$domain"
			exit 0;;
		tcp-curl)
			/usr/bin/track_interface_tcp-curl.sh -i "$interface" -h "$host" -t "$timeout"
			exit 0;;
		*) echo "How the fuck did you get there ?"
			exit 1
	esac
}

check_interface() {
	# check if interface is up
	/usr/bin/track_interface_state.sh -i "$interface"
	# check connectivity using selected method
	_dispatch
}

# Check arguments
while getopts "m:t:h:d:" opt; do
	case $opt in
		m) method="$OPTARG";;
		t) timeout="$OPTARG";;
		h) host="$OPTARG";;
		d) domain="$OPTARG";;
		*) usage;;
	esac
done
shift $((OPTIND - 1))
[ -z "$1" ] && usage
interface="$1"
# check method to check connectivity
[ -z "$method" ] && usage
[ "$( _check_method_argument )" = "$ERROR_CODE" ] && usage
# check timeout
[ -z "$timeout" ] && usage
# check host
[ -z "$host" ] && usage

check_interface
