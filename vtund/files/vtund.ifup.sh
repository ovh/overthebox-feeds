#!/bin/sh
dev=$1
localip=$2
remoteip=$3
metric=$4
table=$5
pref=$6

/sbin/ifconfig $dev $localip pointopoint $remoteip up;
/usr/bin/multipath $dev off;
/usr/sbin/ip rule add from $localip table $table pref $pref;
/usr/sbin/ip route add default via $remoteip table $table;
/usr/sbin/ip route add default via $remoteip metric $metric;
