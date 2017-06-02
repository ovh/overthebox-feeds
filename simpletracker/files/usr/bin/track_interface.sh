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

. /usr/bin/simpletracker.requests

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
		log "Network unreachable on interface '$interface' with ping method";
		/usr/bin/scripts/icmp_infos.sh -i "$interface" -h "$host" -l "$ERROR_CODE"
		exit 1
	fi
	/usr/bin/scripts/icmp_infos.sh -i "$interface" -h "$host" -l "$result";
	exit 0
}

_check_dns_interface() {
	local result=$( dns_request "$interface" "$host" "$domain" "$timeout" )
	if [ "$result" = "$ERROR_CODE" ];then
		log "Network unreachable on interface '$interface' with dns method."
		/usr/bin/scripts/dns_infos.sh -i "$interface" -h "$host" -l "$ERROR_CODE";
		exit 1
	fi
	local latency
	local pub_ip
	local index=0
	for i in $result;do
		[ $index = 0 ] && pub_ip=$i
		[ $index = 1 ] && latency=$i
		index=$(( index + 1 ))
	done
	/usr/bin/scripts/dns_infos.sh -i "$interface" -h "$host" -l "$latency" -p "$pub_ip";
	exit 0
}

# Dispatch between dns and ping method to check
check_interface() {
	# check if interface is up
	local up=$( is_up "$interface" )
	if [ "$up" = "$ERROR_CODE" ];then
		log "Error while using ubus call on interface '$interface'"
		/usr/bin/scripts/interface_status.sh -i "$interface" -s DOWN;
		exit 1
	fi
	/usr/bin/scripts/interface_status.sh -i "$interface" -s UP;
	# check connectivity using selected method
	[ "$method" = "dns" ] && _check_dns_interface
	_check_ping_interface
}
check_interface
