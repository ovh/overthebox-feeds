#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

export SIMPLETRACKER_HOST
export SIMPLETRACKER_DOMAIN
export SIMPLETRACKER_METHOD
export SIMPLETRACKER_TIMEOUT
export SIMPLETRACKER_INTERFACE
export SIMPLETRACKER_INTERFACE_STATE
export SIMPLETRACKER_INTERFACE_LATENCY
export SIMPLETRACKER_INTERFACE_PUBLIC_IP

_init_env_vars() {
	SIMPLETRACKER_INTERFACE_PUBLIC_IP="ERROR"
	SIMPLETRACKER_INTERFACE_LATENCY="ERROR"
	SIMPLETRACKER_INTERFACE_STATE="ERROR"
	SIMPLETRACKER_INTERFACE="if1"
	SIMPLETRACKER_TIMEOUT=2
	SIMPLETRACKER_DOMAIN="tracker.overthebox.ovh"
	SIMPLETRACKER_HOST="51.254.49.133"
}

test_state() {
	_init_env_vars
	/usr/bin/track_interface_state.sh
}

test_icmp() {
	_init_env_vars
	/usr/bin/track_interface_icmp.sh
}

test_udp_dns() {
	_init_env_vars
	/usr/bin/track_interface_udp-dns.sh
}

test_tcp_dns() {
	_init_env_vars
	/usr/bin/track_interface_tcp-dns.sh
}

test_tcp_curl() {
	_init_env_vars
	SIMPLETRACKER_HOST="ifconfig.ovh"
	/usr/bin/track_interface_tcp-curl.sh
}
