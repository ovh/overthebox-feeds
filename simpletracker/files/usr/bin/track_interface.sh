#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0
ERROR_CODE='-1'

usage() {
	printf "Usage : %s: [-m METHOD] [-t TIMEOUT] [-h host] [-d domain] INTERFACE\n\tMethod must be 'dns' or 'ping'\n\tDomain is necessary for dns method only\n" "$name"
	exit 1
}

log() {
	logger -p user.notice -s -t "simpletracker" "$@"
}

. ./simpletracker.requests

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
[ "$method" != "ping" ] && [ "$method" != "dns" ] && usage
# check timeout
[ -z "$timeout" ] && usage
# check host
[ -z "$host" ] && usage
# check domain
[ "$method" = 'dns' ] && [ -z "$domain" ] && usage

# Calls check_ping_interface_for_destination until one destination answers. If no destinations answers, return Error code
_check_ping_interface() {
	local result=$( ping_request "$host" "$interface" "$timeout" )
		if [ "$result" = "$ERROR_CODE" ];then
			log "Network unreachable on interface '$interface' with ping method"
			exit 1
		fi
	echo "$result"
}

_check_dns_interface() {
	local result=$( dns_request "$interface" "$host" "$domain" "$timeout" )
	if [ "$result" = "$ERROR_CODE" ];then
		log "Network unreachable on interface '$interface' with dns method."
		exit 1
	fi
	echo "$result"
	exit 0
}

# Dispatch between dns and ping method to check
check_interface() {
	# check if interface is up
	local up=$( is_up "$interface" )
	[ "$up" = "$ERROR_CODE" ] && log "Error while using ubus call on interface '$interface'" && exit 1
	# check connectivity using selected method
	[ "$method" = "dns" ] && _check_dns_interface
	_check_ping_interface
}
check_interface
