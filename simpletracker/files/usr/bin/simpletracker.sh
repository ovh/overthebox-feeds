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
	echo "icmp" "tcp-dns" "udp-dns" "tcp-curl"
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
		[ "$i" = "$SIMPLETRACKER_METHOD" ] && echo "$OK_CODE" && return
	done
	echo "$ERROR_CODE"
}

_dispatch() {
	case "$SIMPLETRACKER_METHOD" in
		icmp)
			/usr/bin/track_interface_icmp.sh
			exit 0;;
		udp-dns)
			/usr/bin/track_interface_udp-dns.sh
			exit 0;;
		tcp-dns)
			/usr/bin/track_interface_tcp-dns.sh
			exit 0;;
		tcp-curl)
			/usr/bin/track_interface_tcp-curl.sh
			exit 0;;
		*) echo "How the fuck did you get there ?"
			exit 1
	esac
}

check_interface() {
	# check if interface is up
	/usr/bin/track_interface_state.sh
	# check connectivity using selected method
	_dispatch
}

# Check arguments
while getopts "m:t:h:d:" opt; do
	case $opt in
		m) SIMPLETRACKER_METHOD="$OPTARG";;
		t) SIMPLETRACKER_TIMEOUT="$OPTARG";;
		h) SIMPLETRACKER_HOST="$OPTARG";;
		d) SIMPLETRACKER_DOMAIN="$OPTARG";;
		*) usage;;
	esac
done
shift $((OPTIND - 1))
[ -z "$1" ] && usage
SIMPLETRACKER_INTERFACE="$1"
# check method to check connectivity
[ -z "$SIMPLETRACKER_METHOD" ] && usage
[ "$( _check_method_argument )" = "$ERROR_CODE" ] && usage
# check timeout
[ -z "$SIMPLETRACKER_TIMEOUT" ] && usage
# check host
[ -z "$SIMPLETRACKER_HOST" ] && usage

export SIMPLETRACKER_INTERFACE
export SIMPLETRACKER_METHOD
export SIMPLETRACKER_TIMEOUT
export SIMPLETRACKER_HOST
export SIMPLETRACKER_DOMAIN

check_interface
