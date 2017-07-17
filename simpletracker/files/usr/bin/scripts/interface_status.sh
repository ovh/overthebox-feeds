#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

if [ "$SIMPLETRACKER_INTERFACE_STATE" = "DOWN" ];then
	echo Interface "$SIMPLETRACKER_INTERFACE" is DOWN >> /root/logs
	# ubus call -S simpletracker interface_up "{'interface':'$SIMPLETRACKER_INTERFACE','up':false}"
	exit 0
fi
echo Interface "$SIMPLETRACKER_INTERFACE" is UP >> /root/logs
# ubus call -S simpletracker interface_up "{'interface':'$SIMPLETRACKER_INTERFACE','up':true}"
exit 0
