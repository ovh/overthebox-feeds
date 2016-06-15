#
## Copyright (C) 2015 OVH
#
## This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
# #
#

include $(TOPDIR)/rules.mk

PKG_NAME:=iptraf-ng
PKG_VERSION:=1.1.3.1
PKG_RELEASE:=1
PKG_MD5SUM:=09da6949674b39f9998ead63dc2c671002ba27d4

PKG_SOURCE_URL:=http://fedorahosted.org/releases/i/p/iptraf-ng/
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

PKG_MAINTAINER:=Sebastien Duponcheel <sebastien.duponcheel@ovh.net>

include $(INCLUDE_DIR)/package.mk

define Package/iptraf-ng
  SECTION:=net
  CATEGORY:=Network
  TITLE:=iptraf-ng
  DEPENDS:=+libncurses
endef

define Package/iptraf-ng/description
   iptraf-ng is a console-based network statistics utility for Linux. It gathers a variety of figures such as TCP connection packet and byte counts, interface statistics and activity indicators, TCP/UDP traffic breakdowns, and LAN station packet and byte counts.
endef

define Package/iptraf-ng/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iptraf-ng $(1)/usr/sbin/iptraf-ng
endef

$(eval $(call BuildPackage,iptraf-ng))
