#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

if [ "$SIMPLETRACKER_INTERFACE_LATENCY" = "ERROR" ];then
	echo Ping failed >> /root/logs
	exit 1
fi
echo "Ping through $SIMPLETRACKER_INTERFACE on $SIMPLETRACKER_HOST spent $SIMPLETRACKER_INTERFACE_LATENCY milliseconds" >> /root/logs
exit 0
