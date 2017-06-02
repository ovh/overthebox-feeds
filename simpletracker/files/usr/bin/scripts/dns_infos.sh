#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0
ERROR_CODE='-1'

usage() {
	printf "Usage : %s: [-i INTERFACE] [-l LATENCY] [-h HOST] [-p PUBLIC_IP ]\n" "$name"
	exit 1
}

while getopts "i:l:h:p:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		h) host="$OPTARG";;
		l) latency="$OPTARG";;
		p) pub_ip="$OPTARG";;
		*) usage;;
	esac
done

[ -z "$interface" ] && usage
[ -z "$host" ] && usage
[ -z "$latency" ] && usage
[ -z "$pub_ip" ] && usage

if [ "$latency" = "$ERROR_CODE" ];then
	echo DNS failed >> /root/logs
	exit 1
fi
exit 0
