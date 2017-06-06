#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0
ERROR_CODE='-1'

usage() {
	printf "Usage : %s: [-i INTERFACE] [-l LATENCY] [-h HOST] [-d DOMAIN] [-p PUBLIC_IP ]\n" "$name"
	exit 1
}

while getopts "i:l:h:p:d:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		h) host="$OPTARG";;
		l) latency="$OPTARG";;
		p) pub_ip="$OPTARG";;
		d) domain="$OPTARG";;
		*) usage;;
	esac
done

[ -z "$interface" ] && usage
[ -z "$host" ] && usage
[ -z "$latency" ] && usage
[ -z "$pub_ip" ] && usage
[ -z "$domain" ] && usage

if [ "$latency" = "$ERROR_CODE" ];then
	echo FAIL DNS through "$interface" on "$host" >> /root/logs
	exit 1
fi
echo "DNS through $interface on $host for $domain spent $latency ms. Public ip : $pub_ip" >> /root/logs
exit 0
