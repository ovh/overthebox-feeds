#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/angt/glorytun.git
PKG_SOURCE_VERSION:=c15343f8f6fb275fe9bed56ca251bb801ea5d67b

PKG_NAME:=glorytun
PKG_VERSION:=0.0.99-$(PKG_SOURCE_VERSION)
PKG_RELEASE:=17

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

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/glorytun $(1)/usr/sbin/$(PKG_NAME)
	$(INSTALL_BIN) update $(1)/usr/sbin/$(PKG_NAME)-update.sh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	touch $(1)/etc/config/glorytun
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net/
	$(INSTALL_BIN) hotplug $(1)/etc/hotplug.d/net/90-$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) hotplug $(1)/etc/hotplug.d/iface/90-$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/hotplug.d/dhcp/
	$(INSTALL_BIN) hotplug $(1)/etc/hotplug.d/dhcp/90-$(PKG_NAME)
	$(INSTALL_DIR) $(1)/usr/share/otb/config-check.d/
	$(INSTALL_BIN) hotplug $(1)/usr/share/otb/config-check.d/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
