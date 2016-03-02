#!/bin/sh

if [ -z "${dev}" -o -z "${iplocal}" -o -z "${ippeer}" ]; then
    echo "environnement variable is not set"
    echo "run this binary with procd"
    exit 1
fi

statefile=/tmp/glorytun.${dev}.fifo
[ -e "${statefile}" ] && rm -f "${statefile}"
mkfifo ${statefile}

trap "pkill -TERM -P $$" TERM
logger -t glorytun RUN dev ${dev} statefile ${statefile} retry count -1 timeout 5000 $*
glorytun dev ${dev} statefile ${statefile} retry count -1 const 5000000 timeout 5000 $* &

GTPID=$!

initialized() {
    ip addr add ${iplocal} peer ${ippeer} dev ${dev}
    [ -n "${mtu}" ] && ip link set ${dev} mtu ${mtu}
    # Workaround to make mwan3 update tun rule
    /etc/init.d/sqm start ${dev}
    multipath ${dev} off
}

started() {
    ip link set ${dev} up
    if [ -n "${table}" ]; then
        ip rule add from ${iplocal} table ${table} pref ${pref:-0}
        ip route add default via ${ippeer} table ${table}
    fi
    [ -n "${metric}" ] && ip route add default via ${ippeer} metric ${metric}
    ubus call network.interface.${dev} up
    if [ "${dev}" == "tun0" ]; then
        [ -x /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks start ;
    fi
}

stopped() {
    if [ "${dev}" == "tun0" ]; then
    	[ -x /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks stop;
    fi
    if [ -n "${table}" ]; then
        ip rule del from ${iplocal} table ${table}
        ip route del default via ${ippeer} table ${table}
	ip route del default via ${ippeer} metric ${metric}
    fi
    ubus call network.interface.${dev} down
    ip link set ${dev} down
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
