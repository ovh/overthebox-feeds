#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0

usage() {
	printf "Usage : %s: [-m METHOD] [-t TIMEOUT] INTERFACE\n" "$name"
	exit 2
}

log() {
	logger -p user.notice -s -t "simpletracker" "$@"
}

. ./simpletracker.init
. ./simpletracker.requests

# Check arguments
while getopts "m:t:" opt; do
	case $opt in
		m) method="$OPTARG";;
		t) timeout="$OPTARG";;
		*) usage;;
	esac
done
shift $((OPTIND - 1))
[ -z "$1" ] && usage

init

# select method to check connectivity
if [ -z "$method" ]; then
	[ "$ping_enable" = "$ENABLED" ] && method="ping"
	[ "$dns_enable" = "$ENABLED" ] && method="dns"
fi
[ "$method" != "ping" ] && [ "$method" != "dns" ] && log "Invalid tracking method $method" && exit 1

# set timeout
[ -z "$timeout" ] && [ "$method" = "dns" ] && timeout="$dns_timeout"
[ -z "$timeout" ] && [ "$method" = "ping" ] && timeout="$ping_timeout"


# $1=<interface> , $2=<timeout>
# Calls check_ping_interface_for_destination until one destination answers. If no destinations answers, return Error code
_check_ping_interface() {
	for destination in $ping_destinations; do
		local result=$( _check_ping_interface_for_destination "$1" "$destination" "$timeout")
		if [ "$result" = "$OK_CODE" ];then
			echo "$OK_CODE"
			return
		fi
	done
	log "Network unreachable on interface '$1' with ping method."
	echo "$ERROR_CODE"
}

# $1=<interface> $2=<destination> $3=<timeout>
# Returns OK or ERROR code depending on the result.
_check_ping_interface_for_destination() {
	local result=$( ping_request "$2" "$1" "$3" )
	if [ "$result" = "$ERROR_CODE" ]; then
		log "Ping $1 : Failure. Dst: $2. Timeout: $3"
		echo "$ERROR_CODE"
		return
	else
		log "Ping $1 : $result ms."
		echo "$result" > "${path}/latency"
		echo "$OK_CODE"
	fi
}



# $1=<interface>
_check_dns_interface() {
	for resolver in $dns_resolvers; do
		local result=$( _check_dns_interface_with_resolver "$1" "$resolver" "myip.opendns.com" "$timeout" )
		if [ "$result" = "$OK_CODE" ]; then
			echo "$OK_CODE"
			return
		fi      
	done    
	log "Network unreachable on interface '$1' with dns method."
	echo "$ERROR_CODE" 
}

# $1=<interface> , $2=<resolver> , $3=<domain> , $4=<timeout>
_check_dns_interface_with_resolver() {
	local result=$( dns_request "$1" "$2" "$3" "$4" )
	if [ "$result" = "$ERROR_CODE" ]; then
		log "DNS $1 : Failure. Resolver: $2. Domain: $3. Timeout: $4."
		echo "$ERROR_CODE"
	else    
		local i=0
		local latency
		local pub_ip
		for var in $result; do
			[ $i = 0 ] && pub_ip=$var
			[ $i = 1 ] && latency=$var
			i=$(( i+1 ))
		done
		log "DNS '$1' : Latency: $latency ms. Public IP: ${pub_ip}."
		echo "$latency" > "${path}/latency"
		echo "$pub_ip" > "${path}/public_ip"
		echo "$OK_CODE"
	fi      
}       



# $1=<interface>
# Dispatch between dns and ping method to check
check_interface() {
	path="$infos/$1"
	mkdir -p "$path"
	# check if interface is up
	local up=$( is_up "$1" )
	[ "$up" = "$ERROR_CODE" ] && log "Error while using ubus call on interface '$1'" && exit 1
	[ "$up" = "false" ] && rm "${path}"/* && echo DOWN > "${path}/state" && log "Interface $1 is down." && exit 0
	[ "$up" = "true" ] && echo UP > "${path}/state"	
	# check connectivity using selected method
	local result
	if [ "$method" = "dns" ]; then
		result=$( _check_dns_interface "$1" )
	elif [ "$method" = "ping" ]; then
		result=$( _check_ping_interface "$1")
	else
		log "Method passed as argument is incorrect. Must be ping or dns."
		result="$ERROR_CODE"
	fi
	if [ "$result" = "$ERROR_CODE" ]; then
		log "Interface $1 can not reach network."
		exit 2
	fi
}
check_interface "$1" 
