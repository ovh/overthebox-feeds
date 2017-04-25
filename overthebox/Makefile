#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.6
PKG_RELEASE:=0

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
endef

define Package/overthebox/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	for file in /etc/uci-defaults/otb*.defaults; do
		( . "$$file" ) && rm -f "$$file"
	done

	for file in /etc/sysctl.d/*.conf; do
		sysctl -p "$$file"
	done

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
