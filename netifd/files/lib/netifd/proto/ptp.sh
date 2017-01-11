#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

proto_ptp_init_config() {
	proto_config_add_string 'ipaddr:ipaddr'
	proto_config_add_string 'gateway:gateway'

	no_device=1
	available=1
}

proto_ptp_setup() {
	local interface="$1"; shift

	json_select ipv4
	json_get_vars ipaddr gateway

	proto_init_update "$interface" 1
	proto_set_keep 1
	proto_add_ipv4_address "$ipaddr" "255.255.255.255" "" "$gateway"
	proto_add_ipv4_route "0.0.0.0" 0 "$gateway"
	proto_send_update "$interface"
}

proto_ptp_teardown() {
	local interface="$1"
	proto_kill_command "$interface"
}

add_protocol ptp
