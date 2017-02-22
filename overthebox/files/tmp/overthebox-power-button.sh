#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

[ "${ACTION}" = "released" ] || exit 0

_log() {
	logger -p daemon.info -t power.button "$@"
}

# File to keep the timestamps of the last clicks
POWER_FILE=/var/log/power

# Number of clicks to trigger a reset
OCCUR_TRIGGER=5

# Time interval during which the number of clicks should be done
OCCUR_DELAY=5

# Add the current timestamp to the file
date +%s >> ${POWER_FILE}

# Compute the time range starting point
limit=$(($(date +"%s")-OCCUR_DELAY))

# Compute the number of occurrences (number of clicks for the last $OCCUR_DELAY
# seconds)
occur=$(awk '{if($1>'"$limit"')print $1}' ${POWER_FILE} | wc -l)

# Only continue if 5 times in less than 5s
if [ "$occur" -ne ${OCCUR_TRIGGER} ]; then
	exit 0
fi

_log "Power button pressed more than 5 time within 5 sec."
_log "Factory Reset initialized manually by user."

# If the device uses SquashFS, no need to do a full sysupgrade
IS_SQUASHFS=$(mount | grep -c squashfs)
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
