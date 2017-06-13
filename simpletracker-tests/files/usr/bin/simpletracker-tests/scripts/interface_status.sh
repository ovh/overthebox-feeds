#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

if [ "$SIMPLETRACKER_INTERFACE_STATE" = "UP" ];then
	echo OK
elif [ "$SIMPLETRACKER_INTERFACE_STATE" = "DOWN" ];then
	echo FAIL
else
	echo ERROR
fi
