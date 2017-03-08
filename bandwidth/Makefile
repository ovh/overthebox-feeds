#
# Copyright (C) 2016 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bandwidth
PKG_VERSION:=0.6.3
PKG_RELEASE=1
PKG_MAINTAINER:=Martin Wetterwald <martin.wetterwald@corp.ovh.com>

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
	$(INSTALL_BIN) ./files/bandwidth $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)$(SHARE_DIR)
	$(CP) ./files/*.awk $(1)$(SHARE_DIR)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/bandwidth.init $(1)/etc/init.d/bandwidth
endef

define Package/bandwidth/postrm
	#!/bin/sh
	rmdir $(SHARE_DIR)
	exit 0
endef

$(eval $(call BuildPackage,bandwidth))
