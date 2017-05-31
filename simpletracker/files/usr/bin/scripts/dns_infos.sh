#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0
ERROR_CODE='-1'

usage() {
    printf "Usage : %s: [-i INTERFACE] [-l LATENCY] [-h host]\n" "$name"
	exit 1
}

while getopts "i:l:h:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		h) host="$OPTARG";;
		l) latency="$OPTARG";;
		*) usage;;
	esac
done

[ -z "$interface" ] && usage
[ -z "$host" ] && usage
[ -z "$latency" ] && usage

if [ "$latency" = "$ERROR_CODE" ];then
	echo DNS failed
	exit 1
fi
echo DNS through "$interface" on "$host" spent "$latency" ms
exit 0
