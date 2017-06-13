#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

if [ "$SIMPLETRACKER_INTERFACE_PUBLIC_IP" = "FAIL" ];then
	echo FAIL CURL through "$SIMPLETRACKER_INTERFACE" on "$SIMPLETRACKER_HOST" >> /root/logs
	exit 1
fi
echo "CURL through $SIMPLETRACKER_INTERFACE on $SIMPLETRACKER_HOST. Public ip : $SIMPLETRACKER_INTERFACE_PUBLIC_IP" >> /root/logs
exit 0

