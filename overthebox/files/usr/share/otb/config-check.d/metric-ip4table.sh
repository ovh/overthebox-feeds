# shellcheck disable=SC1091
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

# Ensure all wan interfaces have a metric and a ip4table

. /lib/functions.sh

OTB_CONFIG_INTERFACE_METRIC_OFFSET=30
OTB_CONFIG_INTERFACE_TABLE_OFFSET=230

# $1 type
# $2 value
_config_count() {
	uci -q show network | grep -c "$1='$2'"
}

# $1 interface
# $2 type
_remove_duplicates() {
	value=$(uci -q get "network.$1.$2")
	count=$(_config_count "$2" "$value")
	[ "$count" -le 1 ] && return
	otb_info "removing duplicate network config $2 $value for $1"
	uci -q delete "network.$1.$2"
}

# $1 interface
# $2 type
# #3 config offset
_add_missing_value() {
	[ -n "$(uci -q get "network.$1.$2")" ] && return
	value=$3
	while [ "$(_config_count "$2" "$value")" = 1 ]; do value=$((value+1)); done
	otb_info "setup missing network config $2 to $value for $1"
	uci -q set "network.$1.$2=$value"
}

# $1 interface
_add_missing_rule() {
	[ -n "$(uci -q get "network.$1_rule")" ] && return
	table=$(uci -q get "network.$1.ip4table")
	[ -n "$table" ] || return
	otb_info "setup missing network rule to $table for $1"
	uci -q batch <<-EOF
	set network.$1_rule=rule
	set network.$1_rule.lookup=$table
	set network.$1_rule.priority=30200
	EOF
}

_setup_interface() {
	# Don't touch if0
	[ "$1" = "if0" ] && return
	# Don't touch interfaces without devices
	uci -q get "network.$1.ifname" >/dev/null || return

	_remove_duplicates "$1" "metric"
	_remove_duplicates "$1" "ip4table"

	_add_missing_value "$1" "metric" "$OTB_CONFIG_INTERFACE_METRIC_OFFSET"
	_add_missing_value "$1" "ip4table" "$OTB_CONFIG_INTERFACE_TABLE_OFFSET"

	_add_missing_rule "$1"
}

config_load firewall
config_list_foreach wan network _setup_interface

uci -q commit network
