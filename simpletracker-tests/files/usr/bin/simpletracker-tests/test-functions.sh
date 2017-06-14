#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

export SIMPLETRACKER_INTERFACE_STATE
export SIMPLETRACKER_INTERFACE_LATENCY
export SIMPLETRACKER_INTERFACE_PUBLIC_IP
export SIMPLETRACKER_INTERFACE

_init_env_vars() {
	SIMPLETRACKER_INTERFACE_PUBLIC_IP="ERROR"
	SIMPLETRACKER_INTERFACE_LATENCY="ERROR"
	SIMPLETRACKER_INTERFACE_STATE="ERROR"
	SIMPLETRACKER_INTERFACE="if1"
}

test_state() {
	_init_env_vars
	/usr/bin/track_interface_state.sh
}

test_icmp() {
	_init_env_vars
	/usr/bin/simpletracker.sh -t 2 -m icmp -h 51.254.49.133 if1 | tail -n 1
}

test_udp_dns() {
	_init_env_vars
	/usr/bin/simpletracker.sh -t 2 -m udp-dns -h 51.254.49.133 -d tracker.overthebox.ovh if1 | tail -n 1
}

test_tcp_dns() {
	_init_env_vars
	/usr/bin/simpletracker.sh -t 2 -m tcp-dns -h 51.254.49.133 -d tracker.overthebox.ovh if1 | tail -n 1
}

test_tcp_curl() {
	_init_env_vars
	/usr/bin/simpletracker.sh -t 2 -m tcp-curl -h ifconfig.ovh if1 | tail -n 1
}
