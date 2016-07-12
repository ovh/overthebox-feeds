#!/bin/sh

source /lib/functions.sh

if [ -z "${GLORYTUN_DEV}" -o -z "${GLORYTUN_IP_LOCAL}" -o -z "${GLORYTUN_IP_PEER}" -o -z "${GLORYTUN_HOST}" -o -z "${GLORYTUN_PORT}" ]; then
    echo "environnement variable is not set"
    exit 1
fi

: ${GLORYTUN_MTU:=1450}
: ${GLORYTUN_TXQLEN:=1000}

statefile=/tmp/glorytun.${GLORYTUN_DEV}.fifo

rm -f "${statefile}"
mkfifo "${statefile}"

if $1 version | grep mud ; then
    GLORYTUN_ARGS="bind-port ${GLORYTUN_PORT} mtu ${GLORYTUN_MTU} bind "

    add_multipath () {
        config_get ipaddr $1 ipaddr
        config_get multipath $1 multipath
        [ "${multipath}" = "on" ] && GLORYTUN_ARGS="${GLORYTUN_ARGS}${ipaddr},"
    }

    config_load network
    config_foreach add_multipath interface
else
    GLORYTUN_ARGS="retry count -1 const 5000000 timeout 5000 keepalive count 3 idle 10 interval 1 mptcp"
fi

trap "pkill -TERM -P $$" TERM
$* host ${GLORYTUN_HOST} port ${GLORYTUN_PORT} dev ${GLORYTUN_DEV} statefile ${statefile} ${GLORYTUN_ARGS} &
GTPID=$!

initialized() {
    ip addr add ${GLORYTUN_IP_LOCAL} peer ${GLORYTUN_IP_PEER} dev ${GLORYTUN_DEV}
    ip link set ${GLORYTUN_DEV} mtu ${GLORYTUN_MTU}
    ip link set ${GLORYTUN_DEV} txqueuelen ${GLORYTUN_TXQLEN}

    # Workaround to make mwan3 update tun rule
    /etc/init.d/sqm start ${GLORYTUN_DEV}

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

    ubus call network.interface.${GLORYTUN_DEV} up

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

    ubus call network.interface.${GLORYTUN_DEV} down

    ip link set ${GLORYTUN_DEV} down
}

while kill -0 ${GTPID}; do
    read STATE INFO || break
    logger -t $1 ${STATE} ${INFO}
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
