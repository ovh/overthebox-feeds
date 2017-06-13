#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

if [ "$SIMPLETRACKER_INTERFACE_PUBLIC_IP" = "ERROR" ]; then
       	echo ERROR
else
	echo OK
fi
