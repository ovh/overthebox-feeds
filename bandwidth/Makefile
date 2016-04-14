#
# Copyright (C) 2016 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bandwidth
PKG_SOURCE_VERSION:=a68152015904d9cfa3f4e3f5f53c3f34bd699cf2
PKG_VERSION:=0.3
PKG_RELEASE=4
PKG_MAINTAINER:=Martin Wetterwald <martin.wetterwald@corp.ovh.com>


PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE).tar.xz
PKG_SOURCE_URL:=https://github.com/MartinWetterwald/bandwidth.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE)
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE)


SHARE_DIR:=/usr/share/bandwidth


include $(INCLUDE_DIR)/package.mk

define Package/bandwidth
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Bandwidth Monitoring
	PKGARCH:=all
endef

define Package/bandwidth/description
	Lightweight Bandwidth Monitoring by MAC
endef

define Build/Compile
endef

define Package/bandwidth/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bandwidth $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)$(SHARE_DIR)
	$(CP) $(PKG_BUILD_DIR)/*.awk $(1)$(SHARE_DIR)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/bandwidth.init $(1)/etc/init.d/bandwidth
endef

define Package/bandwidth/postrm
	#!/bin/sh
	rmdir $(SHARE_DIR)
	exit 0
endef

$(eval $(call BuildPackage,bandwidth))
