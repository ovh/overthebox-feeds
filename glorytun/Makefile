#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=glorytun
PKG_VERSION:=0.0.8
PKG_RELEASE=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/angt/glorytun.git
PKG_SOURCE_VERSION:=8989138051c17460db8fa442a20243ebc650d3b4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk


define Package/glorytun
        SECTION:=net
        CATEGORY:=Network
	DEPENDS:=+kmod-tun +libsodium
	TITLE:=Glorytun
	URL:=https://github.com/angt/glorytun
	SUBMENU:=VPN
endef

TARGET_CFLAGS += -std=c99
TARGET_CFLAGS += -D_GNU_SOURCE

define Package/glorytun/conffiles
/etc/config/glorytun
endef

define Package/glorytun/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/glorytun $(1)/usr/sbin/
endef


$(eval $(call BuildPackage,glorytun))
