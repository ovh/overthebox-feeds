#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=svfs
PKG_VERSION:=0.8.2
PKG_RELEASE:=1

PKG_SOURCE:=svfs-linux-amd64
PKG_SOURCE_URL:=https://github.com/ovh/svfs/releases/download/v$(PKG_VERSION)

PKG_MAINTAINER:=Bash <bash@ovh.net>

include $(INCLUDE_DIR)/package.mk

define Package/svfs
	SECTION:=utils
	CATEGORY:=OVH
	TITLE:=add svfs
	DEPENDS:= +kmod-fuse
endef

define Package/svfs/description
	add svfs
endef

define Package/svfs/conffiles
/etc/config/svfs
endef

define Build/Prepare
	cp $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/svfs
	strip -s $(PKG_BUILD_DIR)/svfs
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/svfs/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/svfs $(1)/usr/bin
endef

$(eval $(call BuildPackage,svfs))
