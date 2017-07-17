#!/bin/sh
# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 :

_install_scripts() {
	mkdir -p /usr/bin/scripts/save
	cp /usr/bin/scripts/*.sh /usr/bin/scripts/save/
	cp /usr/bin/simpletracker-tests/scripts/*.sh /usr/bin/scripts/
	chmod +x /usr/bin/scripts/*
}

_restore_scripts() {
	rm /usr/bin/scripts/*.sh
	mv /usr/bin/scripts/save/*.sh /usr/bin/scripts/
	chmod +x /usr/bin/scripts/*
}


_install_scripts
/usr/bin/simpletracker-tests/test-normal.sh
/usr/bin/simpletracker-tests/test-ifdown.sh
_restore_scripts
