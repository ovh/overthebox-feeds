#!/bin/sh

if [ -z "${dev}" -o -z "${iplocal}" -o -z "${ippeer}" ]; then
    echo "environnement variable is not set"
    echo "run this binary with procd"
    exit 1
fi

statefile=/tmp/glorytun.fifo
[ -e "${statefile}" ] && rm -f "${statefile}"
mkfifo ${statefile}

trap "pkill -TERM -P $$" TERM
logger -t glorytun RUN dev ${dev} statefile ${statefile} retry count -1 timeout 5000 $*
glorytun dev ${dev} statefile ${statefile} retry count -1 timeout 5000 $* &

GTPID=$!

initialized() {
    ip addr add ${iplocal} peer ${ippeer} dev ${dev}
    [ -n "${mtu}" ] && ip link set ${dev} mtu ${mtu}
    ip link set ${dev} up

    multipath ${dev} off
}

started() {
    if [ -n "${table}" ]; then
        ip rule add from ${iplocal} table ${table} pref ${pref:-0}
        ip route add default via ${ippeer} table ${table}
        [ -n "${metric}" ] && ip route add default via ${ippeer} metric ${metric}
    fi
}

stopped() {
    if [ -n "${table}" ]; then
        ip rule del from ${iplocal} table ${table}
        ip route del default via ${ippeer} table ${table}
    fi
}

while kill -0 ${GTPID}; do
    read STATE INFO || break
    logger -t glorytun ${STATE} ${INFO}
    case ${STATE} in
        INITIALIZED)
            initialized
            ;;
        STARTED)
            started
            ;;
        STOPPED)
            stopped
            ;;
    esac
done < ${statefile}

stopped

logger -t glorytun BYE
