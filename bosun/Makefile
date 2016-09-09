#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bosun
PKG_VERSION:=0.5.0
PKG_RELEASE:=1

PKG_SOURCE:=scollector-linux-amd64
PKG_SOURCE_URL:=https://github.com/bosun-monitor/bosun/releases/download/$(PKG_VERSION)

PKG_MAINTAINER:=Sébastien Duponcheel <sebastien.duponcheel@ovh.net>

include $(INCLUDE_DIR)/package.mk

define Package/bosun
	SECTION:=utils
	CATEGORY:=OVH
	TITLE:=add bosum metric monitor
	DEPENDS:= +libc +libpthread
endef

define Package/bosun/description
	add bosun
endef

define Package/bosun/conffiles
/etc/config/scollector
endef

define Build/Prepare
	cp $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/scollector
	strip -s $(PKG_BUILD_DIR)/scollector
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/bosun/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scollector $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/scollector.init $(1)/etc/init.d/scollector
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/scollector.config $(1)/etc/config/scollector
endef

$(eval $(call BuildPackage,bosun))
