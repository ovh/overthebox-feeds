#
# Copyright (C) 2023 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=glorytun
PKG_VERSION:=0.3.4
PKG_RELEASE:=4
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/angt/$(PKG_NAME)/releases/download/v$(PKG_VERSION)
PKG_HASH:=137d9c525a05bb605163df0465367d36e943715ca773ce43d5ea66f0597600a3
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=net
CATEGORY:=Network
DEPENDS:=+kmod-tun +libsodium +librt
TITLE:=Glorytun
URL:=https://github.com/angt/glorytun
SUBMENU:=VPN
endef

TARGET_CFLAGS += -std=c99 -D_GNU_SOURCE

define Package/$(PKG_NAME)/description
Glorytun is a vpn designed to improve your internet connectivity:
 - Fast and highly secure.
 - Multipath and active failover.
 - Traffic shaping.
 - Path MTU discovery without ICMP.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/sbin/$(PKG_NAME)-udp
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/usr/share/otb/post-tracking.d
	$(INSTALL_BIN) files/* $(1)/usr/share/otb/post-tracking.d
	touch $(1)/etc/config/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
