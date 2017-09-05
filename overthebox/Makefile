#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.5
PKG_RELEASE:=4

PKG_BUILD_DIR:=$(BUILD_DIR)/overthebox-$(PKG_VERSION)

PKG_MAINTAINER:=Simon Lelievre <simon.lelievre@corp.ovh.com>

OTB_VERSION?=$(PKG_VERSION)-$(PKG_RELEASE)

include $(INCLUDE_DIR)/package.mk

define Package/overthebox
	SECTION:=utils
	CATEGORY:=OVH
	TITLE:=overthebox tool
	DEPENDS:= +graph +dnsmasq-full +glorytun +glorytun-udp +luci-app-overthebox +mptcp +shadowsocks-libev
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
	sed -i -e "s/<VERSION>/$(OTB_VERSION)/" ./files/usr/lib/lua/overthebox.lua
	sed -i -e "s/<VERSION>/$(OTB_VERSION)/" ./files/usr/bin/overthebox_emergency_action
endef

define Build/Compile
endef

define Package/overthebox/install
	$(CP) ./files/* $(1)/
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
	$(INSTALL_BIN) ./defaults/uhttpd.defaults $(1)/etc/uci-defaults/uhttpd.defaults
	$(INSTALL_BIN) ./defaults/shadowsocks.defaults $(1)/etc/uci-defaults/shadowsocks.defaults
	$(INSTALL_BIN) ./defaults/vfat.defaults $(1)/etc/uci-defaults/vfat.defaults
	$(INSTALL_BIN) ./defaults/distupgrade.defaults $(1)/etc/uci-defaults/distupgrade.defaults
endef

define Package/overthebox/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	( . /etc/uci-defaults/overthebox.defaults ) && rm -f /etc/uci-defaults/overthebox.defaults
	( . /etc/uci-defaults/otb-network.defaults ) && rm -f /etc/uci-defaults/otb-network.defaults
	( . /etc/uci-defaults/otb-dnsmasq.defaults ) && rm -f /etc/uci-defaults/otb-dnsmasq.defaults
	( . /etc/uci-defaults/otb-firewall.defaults ) && rm -f /etc/uci-defaults/otb-firewall.defaults
	( . /etc/uci-defaults/otb-power.defaults ) && rm -f /etc/uci-defaults/otb-power.defaults
	( . /etc/uci-defaults/otb-recovery.defaults )
	( . /etc/uci-defaults/otb-crontab.defaults ) && rm -f /etc/uci-defaults/otb-crontab.defaults
	( . /etc/uci-defaults/mwan3.defaults ) && rm -f /etc/uci-defaults/mwan3.defaults
	( . /etc/uci-defaults/dscp.defaults ) && rm -f /etc/uci-defaults/dscp.defaults
	( . /etc/uci-defaults/ucitrack.defaults ) && rm -f /etc/uci-defaults/ucitrack.defaults
	( . /etc/uci-defaults/uhttpd.defaults ) && rm -f /etc/uci-defaults/uhttpd.defaults
	( . /etc/uci-defaults/shadowsocks.defaults ) && rm -f /etc/uci-defaults/shadowsocks.defaults
	( . /etc/uci-defaults/vfat.defaults ) && rm -f /etc/uci-defaults/vfat.defaults
	( . /etc/uci-defaults/distupgrade.defaults ) && rm -f /etc/uci-defaults/distupgrade.defaults

	for file in $$(ls /etc/sysctl.d/*.conf); do sysctl -p $$file; done

	[ -x /etc/init.d/qos ] && /etc/init.d/qos enable ;
	[ -x /etc/init.d/dscp ] && /etc/init.d/dscp enable ;

	# Once all defaults are set, we use reload_config that will call
	# /etc/init.d/{service} reload on all services that had some config changes
	[ -d /var/run/config.check ] || /sbin/reload_config

	# force clear luci cache
	rm -fr /tmp/luci-indexcache /tmp/luci-modulecache

	if [ ! -f /root/.ssh_otb_remote.pub ] ; then
		dropbearkey -t rsa -s 4096 -f /root/.ssh_otb_remote |grep ^ssh- > /root/.ssh_otb_remote.pub
	fi
	[ -x /etc/init.d/overtheboxd ] && /etc/init.d/overtheboxd restart ;

	exit 0
fi
endef

$(eval $(call BuildPackage,overthebox))

