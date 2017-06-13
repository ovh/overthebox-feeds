#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

if [ "$SIMPLETRACKER_INTERFACE_LATENCY" = "ERROR" ]; then
       	echo ERROR
elif [ "$SIMPLETRACKER_INTERFACE_LATENCY" = "-1" ];then
	echo FAIL
else
	echo OK
fi
