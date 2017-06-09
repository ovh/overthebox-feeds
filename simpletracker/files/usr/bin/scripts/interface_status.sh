#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0

usage() {
    printf "Usage : %s: [-i INTERFACE] [-s STATUS ]\n" "$name"
	exit 1
}

while getopts "i:s:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		s) status="$OPTARG";;
		*) usage;;
	esac
done

[ -z "$interface" ] && usage
[ -z "$status" ] && usage

if [ "$status" = "DOWN" ];then
	echo Interface "$interface" is DOWN >> /root/logs
	# ubus call -S simpletracker interface_up "{'interface':'$interface','up':false}"
	exit 0
fi
echo Interface "$interface" is UP >> /root/logs
# ubus call -S simpletracker interface_up "{'interface':'$interface','up':true}"
exit 0
