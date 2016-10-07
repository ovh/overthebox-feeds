#!/bin/sh

# Source lib fucntions
. /lib/functions.sh
. /lib/functions/network.sh

PROG_NAME=$(basename $0)

_log() {
    logger -p daemon.info -t ${PROG_NAME} "$@"
}

# Ensure that the env vars are set up
if [ -z "${GLORYTUN_DEV}" -o -z "${GLORYTUN_IP_LOCAL}" -o -z "${GLORYTUN_IP_PEER}" -o -z "${GLORYTUN_HOST}" -o -z "${GLORYTUN_PORT}" ]; then
    _log "environnement variable is not set"
    exit 1
fi

# Set default values for undefined env vars
: ${GLORYTUN_MTU:=1450}
: ${GLORYTUN_TXQLEN:=1000}

# Create a state file
statefile="/tmp/glorytun.${GLORYTUN_DEV}.fifo"
[ -p "${statefile}" ] || mkfifo "${statefile}"

GLORYTUN_ARGS="bind-port ${GLORYTUN_PORT} mtu ${GLORYTUN_MTU} bind "

# This function adds the IP of an interface to the glorytun arguments if it uses
# multipath
add_multipath () {
    config_get ifname $1 ifname
    config_get multipath $1 multipath
    if [ "${multipath}" = "on" -o "${multipath}" = "master" ]; then
        network_get_ipaddr ipaddr ${ifname}

        # Only add the interface to glorytun-udp if the IP is defined
        if [ -n "${ipaddr}" ]; then
            GLORYTUN_ARGS="${GLORYTUN_ARGS}${ipaddr},"
        fi
    fi
}

# Run the add_multipath function for each interface
config_load network
config_foreach add_multipath interface

# Launch glorytun and keep its PID in a a var
$* host ${GLORYTUN_HOST} port ${GLORYTUN_PORT} dev ${GLORYTUN_DEV} statefile ${statefile} ${GLORYTUN_ARGS} &
GTPID=$!

# This function sets up the tun interface
initialized() {
    ip addr add ${GLORYTUN_IP_LOCAL} peer ${GLORYTUN_IP_PEER} dev ${GLORYTUN_DEV}
    ip link set ${GLORYTUN_DEV} txqueuelen ${GLORYTUN_TXQLEN}

    multipath ${GLORYTUN_DEV} off
}

# This function starts the tun interface
started() {
    if [ -n "${GLORYTUN_TABLE}" ]; then
        ip rule add from ${GLORYTUN_IP_LOCAL} table ${GLORYTUN_TABLE} pref ${GLORYTUN_PREF}
        ip route add default via ${GLORYTUN_IP_PEER} table ${GLORYTUN_TABLE}
    fi

    if [ -n "${GLORYTUN_METRIC}" ]; then
        ip route add default via ${GLORYTUN_IP_PEER} metric ${GLORYTUN_METRIC}
    fi

    ip link set ${GLORYTUN_DEV} up
}

# This fuction stops the tun interface
stopped() {
    ip link set ${GLORYTUN_DEV} down

    if [ -n "${GLORYTUN_METRIC}" ]; then
        ip route del default via ${GLORYTUN_IP_PEER} metric ${GLORYTUN_METRIC}
    fi

    if [ -n "${GLORYTUN_TABLE}" ]; then
        ip rule del from ${GLORYTUN_IP_LOCAL} table ${GLORYTUN_TABLE}
        ip route del default via ${GLORYTUN_IP_PEER} table ${GLORYTUN_TABLE}
    fi
}

# This function removes the routes and kill the childs of this proccess
kill_child() {
    pkill -TERM -P $$
}

# This function does some cleanup on the interfaces, statefile and PID
quit() {
    stopped
    rm -f "${statefile}"
    _log -t glorytun BYE
}

# Call the quit function when this script exits
trap 'quit' EXIT

# Catch the term signal and kill all the childrens of this script
trap "kill_child" TERM

# Run a loop while glorytun-udp is running
while kill -0 ${GTPID}; do
    # If the statefile is closed, break the loop
    read STATE INFO || break
    # Log each input from the statefile for easy debugging
    _log -t $1 ${STATE} ${INFO}
    # Run the functions above according to the statefile input
    case ${STATE} in
    INITIALIZED)
        _log "setting up ${GLORYTUN_DEV}"
        initialized
        started
        ;;
    esac
done < ${statefile}
