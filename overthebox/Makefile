#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.0.1
PKG_RELEASE:=0.1

PKG_BUILD_DIR:=$(BUILD_DIR)/overthebox-$(PKG_VERSION)

PKG_MAINTAINER:=Simon Lelievre <simon.lelievre@corp.ovh.com>

include $(INCLUDE_DIR)/package.mk

define Package/overthebox
        SECTION:=utils
        CATEGORY:=OVH
        TITLE:=overthebox tool
        DEPENDS:= +bosun +mwan3otb +shadowsocks-libev +vtund
endef

define Package/overthebox/description
        Overthebox package
endef

define Package/overthebox/conffiles
/etc/config/overthebox
endef

define Build/Prepare
	echo Prepare $(PKG_BUILD_DIR)
endef

define Build/Configure
	echo configure $(PKG_BUILD_DIR)
endef

define Build/Compile
	echo compile $(PKG_BUILD_DIR)
endef

define Package/overthebox/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,overthebox))

