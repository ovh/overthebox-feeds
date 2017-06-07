#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

name=$0
ERROR_CODE='-1'

usage() {
	printf "Usage : %s: [-i INTERFACE] [-h HOST] [-p PUBLIC_IP ]\n" "$name"
	exit 1
}

while getopts "i:h:p:" opt; do
	case $opt in
		i) interface="$OPTARG";;
		h) host="$OPTARG";;
		p) pub_ip="$OPTARG";;
		*) usage;;
	esac
done

[ -z "$interface" ] && usage
[ -z "$host" ] && usage
[ -z "$pub_ip" ] && usage

if [ "$pub_ip" = "$ERROR_CODE" ];then
	echo FAIL CURL through "$interface" on "$host" >> /root/logs
	exit 1
fi
echo "CURL through $interface on $host. Public ip : $pub_ip" >> /root/logs
exit 0

