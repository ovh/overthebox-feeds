# 
# Copyright (C) 2014-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3 or later.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp
PKG_VERSION:=1.0.0
PKG_RELEASE:=4

PKG_MAINTAINER:=Mario Krueger <openwrt@xedp3x.de>
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/mptcp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Multipath TCP configuration scrips
  DEPENDS:=+ip +iptables
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
	$(INSTALL_DIR) $(1)
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,mptcp))
