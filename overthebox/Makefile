#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.1
PKG_RELEASE:=3

PKG_BUILD_DIR:=$(BUILD_DIR)/overthebox-$(PKG_VERSION)

PKG_MAINTAINER:=Simon Lelievre <simon.lelievre@corp.ovh.com>

include $(INCLUDE_DIR)/package.mk

define Package/overthebox
        SECTION:=utils
        CATEGORY:=OVH
        TITLE:=overthebox tool
        DEPENDS:= +bosun +mwan3otb +shadowsocks-libev +vtund +mptcp
endef

define Package/overthebox/description
        Overthebox package
endef

define Package/overthebox/conffiles
/etc/config/overthebox
/etc/config/network
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/overthebox/install
	$(CP) ./files/* $(1)/
	sed -i -e "s/<VERSION>/$PKG_VERSION:$PKG_RELEASE/" $(1)/usr/lib/lua/overthebox.lua 
endef

$(eval $(call BuildPackage,overthebox))

