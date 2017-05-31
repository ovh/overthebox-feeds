#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0
ERROR_CODE='-1'

usage() {
    printf "Usage : %s: [-i INTERFACE] [-s STATUS ]\n" "$name"
	exit 1
}

while getopts "i:l:h:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		s) status="$OPTARG";;
		*) usage;;
	esac
done

[ -z "$interface" ] && usage
[ -z "$status" ] && usage

if [ "$status" = "DOWN" ];then
	echo Interface "$interface" is DOWN
	exit 1
fi
echo Interface "$interface" is UP
exit 0
