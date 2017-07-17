#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

. /usr/bin/simpletracker-tests/test-functions.sh
echo ----- Normal Test -----
result="$(test_state)"
echo "$result" STATE
result="$(test_icmp)"
echo "$result" ICMP
result="$(test_udp_dns)"
echo "$result" UDP DNS
result="$(test_tcp_dns)"
echo "$result" TCP DNS
result="$(test_tcp_curl)"
echo "$result" TCP CURL
echo ----- End of Normal Test -----
