#!/bin/sh

. /lib/functions.sh
. /lib/functions/network.sh

if [ -z "${GLORYTUN_DEV}" -o -z "${GLORYTUN_IP_LOCAL}" -o -z "${GLORYTUN_IP_PEER}" -o -z "${GLORYTUN_HOST}" -o -z "${GLORYTUN_PORT}" ]; then
    echo "environnement variable is not set"
    exit 1
fi

: ${GLORYTUN_MTU:=1450}
: ${GLORYTUN_TXQLEN:=1000}

statefile=/tmp/glorytun.${GLORYTUN_DEV}.fifo
[ -p ${statefile} ] || mkfifo ${statefile}

GLORYTUN_ARGS="bind-port ${GLORYTUN_PORT} mtu ${GLORYTUN_MTU} bind "

add_multipath () {
    config_get ifname $1 ifname
    config_get multipath $1 multipath
    if [ "${multipath}" = "on" ]; then
        network_get_ipaddr ipaddr ${ifname}
        if [ -n "${ipaddr}" ]; then
            GLORYTUN_ARGS="${GLORYTUN_ARGS}${ipaddr},"
        fi
    fi
}

config_load network
config_foreach add_multipath interface

trap "pkill -TERM -P $$" TERM
$* host ${GLORYTUN_HOST} port ${GLORYTUN_PORT} dev ${GLORYTUN_DEV} statefile ${statefile} ${GLORYTUN_ARGS} &
GTPID=$!

initialized() {
    ip addr add ${GLORYTUN_IP_LOCAL} peer ${GLORYTUN_IP_PEER} dev ${GLORYTUN_DEV}
    ip link set ${GLORYTUN_DEV} mtu ${GLORYTUN_MTU}
    ip link set ${GLORYTUN_DEV} txqueuelen ${GLORYTUN_TXQLEN}

    multipath ${GLORYTUN_DEV} off
}

started() {
    ip link set ${GLORYTUN_DEV} up

    if [ -n "${GLORYTUN_TABLE}" ]; then
        ip rule add from ${GLORYTUN_IP_LOCAL} table ${GLORYTUN_TABLE} pref ${GLORYTUN_PREF}
        ip route add default via ${GLORYTUN_IP_PEER} table ${GLORYTUN_TABLE}
    fi

    if [ -n "${GLORYTUN_METRIC}" ]; then
        ip route add default via ${GLORYTUN_IP_PEER} metric ${GLORYTUN_METRIC}
    fi

    if [ "${GLORYTUN_DEV}" == "tun0" ]; then
        [ -x /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks start;
    fi
}

stopped() {
    if [ "${GLORYTUN_DEV}" == "tun0" ]; then
        [ -x /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks stop;
    fi

    if [ -n "${GLORYTUN_TABLE}" ]; then
        ip rule del from ${GLORYTUN_IP_LOCAL} table ${GLORYTUN_TABLE}
        ip route del default via ${GLORYTUN_IP_PEER} table ${GLORYTUN_TABLE}
    fi

    if [ -n "${GLORYTUN_METRIC}" ]; then
        ip route del default via ${GLORYTUN_IP_PEER} metric ${GLORYTUN_METRIC}
    fi

    ip link set ${GLORYTUN_DEV} down
}

quit() {
    stopped
    rm -f ${statefile}
}
trap 'quit' EXIT

while kill -0 ${GTPID}; do
    read STATE INFO || break
    logger -t $1 ${STATE} ${INFO}
    case ${STATE} in
    INITIALIZED)
        logger "setting up ${GLORYTUN_DEV}"
        initialized
        logger "${GLORYTUN_DEV} set up"
        ;;
    STARTED)
        started
        logger "mud connected"
        ;;
    STOPPED)
        stopped
        logger "mud disconnected"
        ;;
    esac
done < ${statefile}

logger -t glorytun BYE
