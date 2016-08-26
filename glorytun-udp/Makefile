#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=glorytun-udp
PKG_VERSION:=0.0.61-mud
PKG_RELEASE:=4
PKG_SOURCE:=glorytun-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/angt/glorytun/releases/download/v$(PKG_VERSION)
PKG_BUILD_DIR:=glorytun-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	DEPENDS:=+kmod-tun +libsodium
	TITLE:=Glorytun
	URL:=https://github.com/angt/glorytun
	SUBMENU:=VPN
endef

TARGET_CFLAGS += -std=c99 -D_GNU_SOURCE

define Package/$(PKG_NAME)/conffiles
/etc/config/glorytun
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/glorytun $(1)/usr/sbin/$(PKG_NAME)
	$(INSTALL_BIN) files/glorytun.sh $(1)/usr/sbin/$(PKG_NAME).sh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) files/glorytun.init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) files/glorytun.defaults $(1)/etc/uci-defaults/$(PKG_NAME).defaults
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
    ( . /etc/uci-defaults/$(PKG_NAME).defaults ) && rm -f /etc/uci-defaults/$(PKG_NAME).defaults
    [ -x /etc/init.d/$(PKG_NAME) ] && /etc/init.d/$(PKG_NAME) restart;
fi
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
