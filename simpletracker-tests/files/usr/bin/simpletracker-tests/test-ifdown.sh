#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

. /usr/bin/simpletracker-tests/test-functions.sh

echo ----- Ifdown Test -----
ubus call network.interface down "{'interface':'if1'}"
result="$(test_state)"
[ "$result" = "OK" ] && echo FAIL STATE
[ "$result" = "FAIL" ] && echo OK STATE
[ "$result" = "ERROR" ] && echo ERROR STATE
result="$(test_icmp)"
[ "$result" = "OK" ] && echo FAIL ICMP
[ "$result" = "FAIL" ] && echo OK ICMP
[ "$result" = "ERROR" ] && echo ERROR ICMP
result="$(test_udp_dns)"
[ "$result" = "OK" ] && echo FAIL UDP DNS
[ "$result" = "FAIL" ] && echo OK UDP DNS
[ "$result" = "ERROR" ] && echo ERROR UDP DNS
result="$(test_tcp_dns)"
[ "$result" = "OK" ] && echo FAIL TCP DNS
[ "$result" = "FAIL" ] && echo OK TCP DNS
[ "$result" = "ERROR" ] && echo ERROR TCP DNS
result="$(test_tcp_curl)"
[ "$result" = "OK" ] && echo FAIL CURL
[ "$result" = "FAIL" ] && echo OK CURL
[ "$result" = "ERROR" ] && echo ERROR CURL
echo ----- End of Ifdown Test -----
ubus call network.interface up "{'interface':'if1'}"
