#!/bin/sh

if [ -z "${dev}" -o -z "${iplocal}" -o -z "${ippeer}" ]; then
    echo "environnement variable is not set"
    echo "run this binary with procd"
    exit 1
fi

STATE=/tmp/glorytun.fifo
mkfifo $STATE

trap "pkill -TERM -P $$" TERM
echo glorytun dev ${dev} statefile $STATE retry count -1 $*  | logger -t glorytun
glorytun dev ${dev} statefile $STATE retry count -1 $* &
GTPID=$!

up() {
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
}

down() {
    logger -t glorytun STOP

    if [ -n "${table}" ]; then
	ip rule del from ${iplocal} table ${table}
	ip route del default via ${ippeer} table ${table}
    fi
}

while true; do
    kill -0 ${GTPID} || break
    read line || break
    case $line in
	STARTED)
	    logger -t glorytun UP
	    up
	    ;;
	STOPPED)
	    logger -t glorytun DOWN
	    down
	    ;;
	*)
	    logger -t glorytun unknown : $line
	    ;;
    esac
done < $STATE

down
logger -t glorytun BYE
