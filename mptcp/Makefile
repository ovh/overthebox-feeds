#
# Copyright (C) 2014-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3 or later.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp
PKG_VERSION:=2.6.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Mario Krueger <openwrt@xedp3x.de>
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/mptcp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Multipath TCP configuration scrips
  DEPENDS:=+ip +iptables-nft
  KCONFIG:=\
      CONFIG_MPTCP=y \
      CONFIG_MPTCP_IPV6=y \
      CONFIG_INET_MPTCP_DIAG=m \
  PKGARCH:=all
endef

define Package/mptcp/description
  MultiPath TCP (MPTCP) is an effort towards enabling the simultaneous use of
  several IP-addresses/interfaces by a modification of TCP that presents a regular
  TCP interface to applications, while in fact spreading data across several
  subflows. Benefits of this include better resource utilization, better throughput
  and smoother reaction to failures.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/mptcp/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) multipath $(1)/bin/multipath
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net/
	$(INSTALL_BIN) hotplug-net $(1)/etc/hotplug.d/net/03-$(PKG_NAME)
	$(INSTALL_DIR) $(1)/usr/share/otb/post-tracking.d/
	$(INSTALL_BIN) post-tracking $(1)/usr/share/otb/post-tracking.d/$(PKG_NAME)
endef

$(eval $(call BuildPackage,mptcp))
