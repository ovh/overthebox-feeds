#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/angt/glorytun.git
PKG_SOURCE_VERSION:=0e052dc2db1f71ba0538b06cea7f2701727d4963

PKG_NAME:=glorytun
PKG_VERSION:=0.0.99-$(PKG_SOURCE_VERSION)
PKG_RELEASE:=18

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

TARGET_CPPFLAGS += -DGT_RUNDIR=\\\"/var/run/$(PKG_NAME)\\\"

define Package/$(PKG_NAME)/conffiles
/etc/config/glorytun
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	echo "$(PKG_VERSION)" > $(PKG_BUILD_DIR)/VERSION
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/glorytun $(1)/usr/sbin/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	touch $(1)/etc/config/glorytun
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
