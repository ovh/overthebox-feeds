#!/bin/sh

if [ -z "${dev}" -o -z "${iplocal}" -o -z "${ippeer}" ]; then
        echo "environnement variable is not set"
        echo "run this binary with procd"
        exit 1
fi

trap "pkill -P $$" TERM
glorytun dev ${dev} retry count 0 $* &
GTPID=$!

logger -t glorytun START

while true; do
        kill -0 ${GTPID} || exit 1
        [ -n "$(lsof -p ${GTPID} | grep ESTABLISHED)" ] && break
        sleep 1
done

logger -t glorytun SETUP ${dev}

ip addr add ${iplocal} peer ${ippeer} dev ${dev}
[ -n "${mtu}" ] && ip link set ${dev} mtu ${mtu}
ip link set ${dev} up

multipath ${dev} off

[ -z "${pref}" ] && pref=0

if [ -n "${table}" ]; then
        ip rule add from ${iplocal} table ${table} pref ${pref}
        ip route add default via ${ippeer} table ${table}
        [ -n "${metric}" ] && ip route add default via ${ippeer} metric ${metric}
fi

logger -t glorytun RUNNING

wait

logger -t glorytun STOP

if [ -n "${table}" ]; then
        ip rule del from ${iplocal} table ${table}
        ip route del default via ${ippeer} table ${table}
fi
