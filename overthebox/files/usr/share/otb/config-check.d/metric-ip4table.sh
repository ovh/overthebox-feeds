# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

# Ensure that all lan/wan interfaces have a private routing table

_get_table() {
	table=200
	while uci -q show network | grep -s -q "ip4table='$table'"; do
		table=$((table+1))
	done
}

for iface in $(uci -q get firewall.wan.network); do
	[ "$iface" = wan ] && continue
	[ "$(uci -q get "network.$iface.ifname")" ] || continue
	[ "$(uci -q get "network.${iface}_rule")" ] && continue
	table="$(uci -q get "network.$iface.ip4table")"
	[ "$table" ] || _get_table
	otb_info "setup missing network rule to $table for $iface"
	uci -q batch <<-EOF
	set network.$iface.ip4table=$table
	set network.${iface}_rule=rule
	set network.${iface}_rule.lookup=$table
	set network.${iface}_rule.priority=30200
	EOF
done

if [ "$(uci -q get "network.lan_rule")" != rule ]; then
	otb_info "setup missing lan rule"
	uci -q batch <<-EOF
	set network.lan_rule=rule
	set network.lan_rule.lookup=50
	set network.lan_rule.priority=100
	EOF
fi

for iface in $(uci -q get firewall.lan.network); do
	if [ "$(uci -q get "network.$iface.ip4table")" != 50 ]; then
		otb_info "setup missing network table to lan for $iface"
		uci -q set "network.$iface.ip4table=50"
	fi
done

uci -q commit network
