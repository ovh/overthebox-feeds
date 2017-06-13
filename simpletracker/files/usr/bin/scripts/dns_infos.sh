#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

if [ "$SIMPLETRACKER_INTERFACE_LATENCY" = "FAIL" ];then
	echo FAIL DNS through "$SIMPLETRACKER_INTERFACE" on "$SIMPLETRACKER_HOST" >> /root/logs
	exit 1
fi
echo "DNS through $SIMPLETRACKER_INTERFACE on $SIMPLETRACKER_HOST for $SIMPLETRACKER_DOMAIN spent $SIMPLETRACKER_INTERFACE_LATENCY ms. Public ip : $SIMPLETRACKER_INTERFACE_PUBLIC_IP" >> /root/logs
exit 0
