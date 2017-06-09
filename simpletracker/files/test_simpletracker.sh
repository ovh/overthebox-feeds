#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

##################################################################
# Use this script to test the simpletracker
# It first tests the behavior of each tracking method.
# Then it launches different scenarios to ensure that tracker has the wanted behavior
#####################################################################################

ERROR_CODE=-1
FAIL_CODE=1
OK_CODE=0

# Test state tracker
test_state() {
/usr/bin/track_interface_state.sh -i if1
log=$( logread -e simpletracker | tail -n 1 | grep STATE )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	result="$ERROR_CODE"
elif [ -n "$logfail" ]; then
	result="$FAIL_CODE"
else
	result="$OK_CODE"
fi
}

# Test ICMP tracker
test_icmp() {
/usr/bin/track_interface_icmp.sh -i if1 -t 2 -h 51.254.49.133
log=$( logread -e simpletracker | tail -n 1 | grep ICMP )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	result="$ERROR_CODE"
elif [ -n "$logfail" ]; then
	result="$FAIL_CODE"
else
	result="$OK_CODE"
fi
}

# Test UDP DNS tracker
test_udp_dns() {
/usr/bin/track_interface_udp-dns.sh -i if1 -t 2 -h 51.254.49.133 -d tracker.overthebox.ovh
log=$( logread -e simpletracker | tail -n 1 | grep DNS )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	result="$ERROR_CODE"
elif [ -n "$logfail" ]; then
	result="$FAIL_CODE"
else
	result="$OK_CODE"
fi
}

# Test TCP DNS tracker
test_tcp_dns() {
/usr/bin/track_interface_tcp-dns.sh -i if1 -t 2 -h 51.254.49.133 -d tracker.overthebox.ovh
log=$( logread -e simpletracker | tail -n 1 | grep DNS )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	result="$ERROR_CODE"
elif [ -n "$logfail" ]; then
	result="$FAIL_CODE"
else
	result="$OK_CODE"
fi
}

# Test TCP CURL tracker
test_tcp_curl() {
/usr/bin/track_interface_tcp-curl.sh -i if1 -t 2 -h ifconfig.ovh
log=$( logread -e simpletracker | tail -n 1 | grep CURL )
logfail=$( echo "$log" | grep FAIL )
if [ -z "$log" ]; then
	result="$ERROR_CODE"
elif [ -n "$logfail" ]; then
	result="$FAIL_CODE"
else
	result=$OK_CODE
fi
}

# Classic test
echo ----- Starting classic test
test_state
[ "$result" = "$ERROR_CODE" ] && echo STATE ERROR
[ "$result" = "$FAIL_CODE" ] && echo STATE FAIL
[ "$result" = "$OK_CODE" ] && echo STATE OK
test_icmp
[ "$result" = "$ERROR_CODE" ] && echo ICMP ERROR
[ "$result" = "$FAIL_CODE" ] && echo ICMP FAIL
[ "$result" = "$OK_CODE" ] && echo ICMP OK
test_udp_dns
[ "$result" = "$ERROR_CODE" ] && echo UDP DNS ERROR
[ "$result" = "$FAIL_CODE" ] && echo UDP DNS FAIL
[ "$result" = "$OK_CODE" ] && echo UDP DNS OK
test_tcp_dns
[ "$result" = "$ERROR_CODE" ] && echo TCP DNS ERROR
[ "$result" = "$FAIL_CODE" ] && echo TCP DNS FAIL
[ "$result" = "$OK_CODE" ] && echo TCP DNS OK
test_tcp_curl
[ "$result" = "$ERROR_CODE" ] && echo CURL ERROR
[ "$result" = "$FAIL_CODE" ] && echo CURL FAIL
[ "$result" = "$OK_CODE" ] && echo CURL OK

# If1 gets DOWN
echo ----- if1 gets down
ubus call -S network.interface down '{"interface":"if1"}'
test_state
[ "$result" = "$ERROR_CODE" ] && echo STATE ERROR
[ "$result" = "$FAIL_CODE" ] && echo STATE OK
[ "$result" = "$OK_CODE" ] && echo STATE FAIL
test_icmp
[ "$result" = "$ERROR_CODE" ] && echo ICMP ERROR
[ "$result" = "$FAIL_CODE" ] && echo ICMP OK
[ "$result" = "$OK_CODE" ] && echo ICMP FAIL
test_udp_dns
[ "$result" = "$ERROR_CODE" ] && echo UDP DNS ERROR
[ "$result" = "$FAIL_CODE" ] && echo UDP DNS OK
[ "$result" = "$OK_CODE" ] && echo UDP DNS FAIL
test_tcp_dns
[ "$result" = "$ERROR_CODE" ] && echo TCP DNS ERROR
[ "$result" = "$FAIL_CODE" ] && echo TCP DNS OK
[ "$result" = "$OK_CODE" ] && echo TCP DNS FAIL
test_tcp_curl
[ "$result" = "$ERROR_CODE" ] && echo CURL ERROR
[ "$result" = "$FAIL_CODE" ] && echo CURL OK
[ "$result" = "$OK_CODE" ] && echo CURL FAIL
echo ----- if1 gets up
ubus call -S network.interface up '{"interface":"if1"}'
