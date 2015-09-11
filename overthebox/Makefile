#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.1
PKG_RELEASE:=28

PKG_BUILD_DIR:=$(BUILD_DIR)/overthebox-$(PKG_VERSION)

PKG_MAINTAINER:=Simon Lelievre <simon.lelievre@corp.ovh.com>

include $(INCLUDE_DIR)/package.mk

define Package/overthebox
        SECTION:=utils
        CATEGORY:=OVH
        TITLE:=overthebox tool
        DEPENDS:= +bosun +mwan3otb +shadowsocks-libev +vtund +mptcp
endef

define Package/overthebox/description
        Overthebox package
endef

define Package/overthebox/conffiles
/etc/config/overthebox
/etc/config/network
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
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./defaults/overthebox.defaults $(1)/etc/uci-defaults/overthebox.defaults
	$(INSTALL_BIN) ./defaults/network.defaults $(1)/etc/uci-defaults/otb-network.defaults
	$(INSTALL_BIN) ./defaults/dnsmasq.defaults $(1)/etc/uci-defaults/otb-dnsmasq.defaults
	$(INSTALL_BIN) ./defaults/firewall.defaults $(1)/etc/uci-defaults/otb-firewall.defaults
endef

define Package/overthebox/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
        ( . /etc/uci-defaults/overthebox.defaults ) && rm -f /etc/uci-defaults/overthebox.defaults
	
        ( . /etc/uci-defaults/otb-network.defaults ) && (
		[ -x /etc/init.d/network ] && /etc/init.d/network restart ;
		[ -x /etc/init.d/openvpn ] && /etc/init.d/openvpn restart ;
		[ -x /etc/init.d/vtund ] && /etc/init.d/vtund restart ;
	)
	rm -f /etc/uci-defaults/otb-network.defaults

        ( . /etc/uci-defaults/otb-dnsmasq.defaults ) && rm -f /etc/uci-defaults/otb-dnsmasq.defaults
        ( . /etc/uci-defaults/otb-firewall.defaults ) && rm -f /etc/uci-defaults/otb-firewall.defaults

	[ -x /etc/init.d/dnsmasq ] && /etc/init.d/dnsmasq restart ;
	[ -x /etc/init.d/overthebox ] && /etc/init.d/overthebox restart
        exit 0
fi
endef



$(eval $(call BuildPackage,overthebox))

