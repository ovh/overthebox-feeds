#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bosun
PKG_VERSION:=0.2.0
PKG_RELEASE:=0.6

PKG_SOURCE:=$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/bosun-monitor/bosun/archive/
PKG_MD5SUM:=b9fc38d3c1518f5c86dc4dddf3a5b893

PKG_BUILD_DIR:=$(BUILD_DIR)/bosun-$(PKG_VERSION)

PKG_MAINTAINER:=DUPONCHEEL Sébastien <sebastien.duponcheel@ovh.net>

include $(INCLUDE_DIR)/uclibc++.mk
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

define Build/Configure
	mkdir $(PKG_BUILD_DIR)/src
	ln -s $(PKG_BUILD_DIR) $(PKG_BUILD_DIR)/src/bosun.org
endef

define Build/Compile
	cd $(PKG_BUILD_DIR)/cmd/scollector; \
	GOPATH=$(PKG_BUILD_DIR) go build
endef

define Package/bosun/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cmd/scollector/scollector $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/scollector.init $(1)/etc/init.d/scollector
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/scollector.config $(1)/etc/config/scollector
endef

$(eval $(call BuildPackage,bosun,+libc))
