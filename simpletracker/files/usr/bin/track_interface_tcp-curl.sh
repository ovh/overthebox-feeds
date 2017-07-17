#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

log() {
	logger -p user.notice -t "simpletracker" "$@"
}

# Script call
response="$( curl -s --interface "$SIMPLETRACKER_INTERFACE" -m "$SIMPLETRACKER_TIMEOUT" "$SIMPLETRACKER_HOST" )"
if [ -n "$response" ] ; then
	SIMPLETRACKER_INTERFACE_PUBLIC_IP="$response"
	log CURL: "$SIMPLETRACKER_INTERFACE" to "$SIMPLETRACKER_HOST"
else
	SIMPLETRACKER_INTERFACE_PUBLIC_IP="FAIL"
	log FAIL CURL: "$SIMPLETRACKER_INTERFACE" to "$SIMPLETRACKER_HOST"
fi
export SIMPLETRACKER_INTERFACE_PUBLIC_IP
/usr/bin/scripts/curl_infos.sh
exit 0
