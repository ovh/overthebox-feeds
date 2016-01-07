#
# Copyright (C) 2006-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ndisc6
PKG_VERSION:=1.0.3
PKG_RELEASE:=1
PKG_MD5SUM:=21afdaa3a5a5c1ce50eb7f2b7d795989

PKG_SOURCE_URL:=http://www.remlab.net/files/ndisc6/
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2

include $(INCLUDE_DIR)/package.mk

define Package/ndisc
  SECTION:=ipv6
  CATEGORY:=IPv6
  SUBMENU:=IPv6 discovery tools
  TITLE:=IPv6 discovery tools
  URL:=http://people.via.ecp.fr/~rem/ndisc6/
endef

define Package/ndisc/description
IPv6 discovery tools
endef

define Package/ndisc6
  $(call Package/ndisc)
  TITLE:=An ICMPv6 neighbour discovery tool
endef

define Package/ndisc6/description
An ICMPv6 neighbour discovery tools
endef

define Package/rdisc6
  $(call Package/ndisc)
  TITLE:=An ICMPv6 router discovery tool
endef

define Package/rdisc6/description
An ICMPv6 router discovery tool
endef

define Package/tcptraceroute6
  $(call Package/ndisc)
  TITLE:=A TCP/IPv6-based traceroute implementation
endef

define Package/tcptraceroute6/description
A TCP/IPv6-based traceroute implementation
endef

define Package/rdnssd
  $(call Package/ndisc)
  TITLE:=DNS server discovery daemon
  DEPENDS:=+librt
endef

define Package/rdnssd/description
A recursive DNS server discovery daemon gathering
information through stateless IPv6 autoconfiguration (RFC5006)
endef


define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) -std=c99" \
		all
endef

define Package/ndisc6/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ndisc6 $(1)/usr/bin/
endef

define Package/rdisc6/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/rdisc6 $(1)/usr/bin/
endef

define Package/tcptraceroute6/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tcptraceroute6 $(1)/usr/bin/
endef

define Package/rdnssd/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rdnssd/rdnssd $(1)/usr/bin/
endef

$(eval $(call BuildPackage,ndisc6))
$(eval $(call BuildPackage,rdisc6))
$(eval $(call BuildPackage,tcptraceroute6))
$(eval $(call BuildPackage,rdnssd))
