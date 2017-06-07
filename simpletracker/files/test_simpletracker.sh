#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

##################################################################
# Use this script to test the simpletracker
# It first tests the behavior of each tracking method.
# Then it launches different scenarios to ensure that tracker has the wanted behavior
#####################################################################################

# Test state tracker
/usr/bin/track_interface_state.sh -i if1
log=$( logread -e simpletracker | tail -n 1 | grep STATE )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	echo STATE ERROR
elif [ -n "$logfail" ]; then
	echo STATE FAIL
else
	echo STATE OK
fi

# Test ICMP tracker
/usr/bin/track_interface_icmp.sh -i if1 -t 2 -h 51.254.49.133
log=$( logread -e simpletracker | tail -n 1 | grep ICMP )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	echo ICMP ERROR
elif [ -n "$logfail" ]; then
	echo ICMP FAIL
else
	echo ICMP OK
fi

# Test UDP DNS tracker
/usr/bin/track_interface_udp-dns.sh -i if1 -t 2 -h 51.254.49.133 -d tracker.overthebox.ovh
log=$( logread -e simpletracker | tail -n 1 | grep DNS )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	echo UDP DNS ERROR
elif [ -n "$logfail" ]; then
	echo UDP DNS FAIL
else
	echo UDP DNS OK
fi

# Test TCP DNS tracker
/usr/bin/track_interface_tcp-dns.sh -i if1 -t 2 -h 51.254.49.133 -d tracker.overthebox.ovh
log=$( logread -e simpletracker | tail -n 1 | grep DNS )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	echo TCP DNS ERROR
elif [ -n "$logfail" ]; then
	echo TCP DNS FAIL
else
	echo TCP DNS OK
fi

# Test TCP CURL tracker
/usr/bin/track_interface_tcp-curl.sh -i if1 -t 2 -h ifconfig.ovh
log=$( logread -e simpletracker | tail -n 1 | grep CURL )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	echo CURL ERROR
elif [ -n "$logfail" ]; then
	echo CURL FAIL
else
	echo CURL OK
fi
