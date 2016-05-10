#
## Copyright (C) 2015 OVH
#
## This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
# #
#

include $(TOPDIR)/rules.mk

PKG_NAME:=iptraf
PKG_VERSION:=3.0.0
PKG_RELEASE:=1
PKG_MD5SUM:=377371c28ee3c21a76f7024920649ea8

PKG_SOURCE_URL:=ftp://iptraf.seul.org/pub/iptraf/
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

PKG_MAINTAINER:=Sebastien Duponcheel <sebastien.duponcheel@ovh.net>

include $(INCLUDE_DIR)/package.mk

define Package/iptraf
  SECTION:=net
  CATEGORY:=Network
  TITLE:=iptraf
  DEPENDS:=+terminfo +libncurses
endef

define Package/iptraf/description
   IPTraf is a console-based network statistics utility for Linux. It gathers a variety of figures such as TCP connection packet and byte counts, interface statistics and activity indicators, TCP/UDP traffic breakdowns, and LAN station packet and byte counts.
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/src clean
	$(MAKE) -C $(PKG_BUILD_DIR)/support clean
	$(MAKE) -C $(PKG_BUILD_DIR)/support all
	$(MAKE) -C $(PKG_BUILD_DIR)/src iptraf
endef

define Package/iptraf/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/iptraf $(1)/usr/sbin/iptraf
endef

$(eval $(call BuildPackage,iptraf))
