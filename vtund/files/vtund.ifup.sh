#!/bin/sh
dev=$1
localip=$2
remoteip=$3
metric=$4
table=$5
pref=$6
mtu=$7

/sbin/ifconfig $dev $localip pointopoint $remoteip up;
/sbin/ifconfig $dev mtu $mtu;
/usr/bin/multipath $dev off;
/usr/sbin/ip rule add from $localip table $table pref $pref;
/usr/sbin/ip route add default via $remoteip table $table;
/usr/sbin/ip route add default via $remoteip metric $metric;
