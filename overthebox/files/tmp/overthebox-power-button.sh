#!/bin/sh

[ "${ACTION}" = "released" ] || exit 0

_log() {
    logger -p daemon.info -t power.button "$@"
}

POWER_FILE=/var/log/power
OCCUR_TRIGGER=5
OCCUR_DELAY=5

echo `date +"%s"`   >> ${POWER_FILE}

limit=$((`date +"%s"`-${OCCUR_DELAY}))
occur=`cat ${POWER_FILE}  | awk '{if($1>'"$limit"')print $1}' | wc -l`

# Only continue if 5 times in less than 5s
if [ "$occur" -ne ${OCCUR_TRIGGER} ]; then
    exit 0
fi

_log "Power button pressed more than 5 time within 5 sec."
_log "Factory Reset initialized manually by user."

# If the device uses SquashFS, no need to do a full sysupgrade
IS_SQUASHFS=$(mount | grep squashfs | wc -l)
if [ "${IS_SQUASHFS}" -ge 1 ]; then
    _log "Factory reset using mtd on squashfs"
    mtd -r erase rootfs_data
    exit 1
fi

if [ -f /recovery/recovery.img.gz ]; then
    _log "Factory reset using recovery image on ext4"
    cd /recovery/ && sysupgrade -n recovery.img.gz
else
    _log "Factory Reset requested but rom file doesn't exists"
    exit 1
fi
