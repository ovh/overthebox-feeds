#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.3
PKG_RELEASE:=14

PKG_BUILD_DIR:=$(BUILD_DIR)/overthebox-$(PKG_VERSION)

PKG_MAINTAINER:=Simon Lelievre <simon.lelievre@corp.ovh.com>

include $(INCLUDE_DIR)/package.mk

define Package/overthebox
        SECTION:=utils
        CATEGORY:=OVH
        TITLE:=overthebox tool
        DEPENDS:= +bosun +mwan3otb +shadowsocks-libev +vtund +mptcp +rdisc6
endef

define Package/overthebox/description
        Overthebox package
endef

define Package/overthebox/conffiles
/etc/config/overthebox
/etc/config/network
/etc/config/dscp
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/overthebox/install
	$(CP) ./files/* $(1)/
	sed -i -e "s/<VERSION>/$(PKG_VERSION)-$(PKG_RELEASE)/" $(1)/usr/lib/lua/overthebox.lua 
	sed -i -e "s/<VERSION>/$(PKG_VERSION)-$(PKG_RELEASE)/" $(1)/usr/bin/overthebox_emergency_action 
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./defaults/overthebox.defaults $(1)/etc/uci-defaults/overthebox.defaults
	$(INSTALL_BIN) ./defaults/network.defaults $(1)/etc/uci-defaults/otb-network.defaults
	$(INSTALL_BIN) ./defaults/dnsmasq.defaults $(1)/etc/uci-defaults/otb-dnsmasq.defaults
	$(INSTALL_BIN) ./defaults/firewall.defaults $(1)/etc/uci-defaults/otb-firewall.defaults
	$(INSTALL_BIN) ./defaults/power.defaults $(1)/etc/uci-defaults/otb-power.defaults
	$(INSTALL_BIN) ./defaults/crontab.defaults $(1)/etc/uci-defaults/otb-crontab.defaults
	$(INSTALL_BIN) ./defaults/download_recovery.defaults $(1)/etc/uci-defaults/otb-recovery.defaults
	$(INSTALL_BIN) ./defaults/mwan3.defaults $(1)/etc/uci-defaults/mwan3.defaults
	$(INSTALL_BIN) ./defaults/dscp.defaults $(1)/etc/uci-defaults/dscp.defaults
	$(INSTALL_BIN) ./defaults/ucitrack.defaults $(1)/etc/uci-defaults/ucitrack.defaults
endef

define Package/overthebox/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
        ( . /etc/uci-defaults/overthebox.defaults ) && rm -f /etc/uci-defaults/overthebox.defaults
        ( . /etc/uci-defaults/otb-network.defaults ) && rm -f /etc/uci-defaults/otb-network.defaults
        ( . /etc/uci-defaults/otb-dnsmasq.defaults ) && rm -f /etc/uci-defaults/otb-dnsmasq.defaults
        ( . /etc/uci-defaults/otb-firewall.defaults ) && rm -f /etc/uci-defaults/otb-firewall.defaults
        ( . /etc/uci-defaults/otb-power.defaults ) 
        ( . /etc/uci-defaults/otb-recovery.defaults ) 
	( . /etc/uci-defaults/otb-crontab.defaults ) && rm -f /etc/uci-defaults/otb-crontab.defaults
	( . /etc/uci-defaults/mwan3.defaults ) && rm -f /etc/uci-defaults/mwan3.defaults
	( . /etc/uci-defaults/dscp.defaults ) && rm -f /etc/uci-defaults/dscp.defaults
	( . /etc/uci-defaults/ucitrack.defaults ) && rm -f /etc/uci-defaults/ucitrack.defaults

	sysctl -p /etc/sysctl.d/default.conf

	[ -x /etc/init.d/dnsmasq ] && /etc/init.d/dnsmasq restart ;

	# force clear luci cache
	rm -fr /tmp/luci-indexcache /tmp/luci-modulecache

	MD5="e8ed1b70b4b1972ffca620b255a1373b"
	if [ "$$(md5sum /lib/upgrade/platform.sh | cut -f1 -d" ")" != "$$MD5" ]
	then
	    wget -q http://downloads.overthebox.ovh/trunk/x86/64/platform.sh -O /tmp/platform.sh
	    if [ "$$(md5sum /tmp/platform.sh | cut -f1 -d" ")" == "$$MD5" ] 
	    then
		mv /tmp/platform.sh /lib/upgrade/platform.sh
	    fi
	fi
	if [ ! -f /root/.ssh_otb_remote.pub ] ; then
		dropbearkey -t rsa -s 4096 -f /root/.ssh_otb_remote |grep ^ssh- > /root/.ssh_otb_remote.pub
	fi
	[ -x /etc/init.d/overtheboxd ] && /etc/init.d/overtheboxd restart ;
	exit 0
fi
endef



$(eval $(call BuildPackage,overthebox))

