#
# Copyright (C) 2014-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3 or later.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp
PKG_VERSION:=2.5.1
PKG_RELEASE:=1

PKG_MAINTAINER:=Mario Krueger <openwrt@xedp3x.de>
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/mptcp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Multipath TCP configuration scrips
  DEPENDS:=+ip +iptables
  KCONFIG:=\
      CONFIG_MPTCP=y \
      CONFIG_MPTCP_BINDER=y \
      CONFIG_MPTCP_FULLMESH=y \
      CONFIG_MPTCP_NDIFFPORTS=y \
      CONFIG_MPTCP_PM_ADVANCED=y \
      CONFIG_MPTCP_REDUNDANT=y \
      CONFIG_MPTCP_ROUNDROBIN=y \
      CONFIG_MPTCP_SCHED_ADVANCED=y \
      CONFIG_DEFAULT_FULLMESH=y \
      CONFIG_DEFAULT_NDIFFPORTS=n \
      CONFIG_DEFAULT_REDUNDANT=n \
      CONFIG_DEFAULT_ROUNDROBIN=n \
      CONFIG_DEFAULT_SCHEDULER=y \
      CONFIG_DEFAULT_BINDER=n \
      CONFIG_DEFAULT_DUMMY=n \
      CONFIG_TCP_CONG_BALIA=n \
      CONFIG_TCP_CONG_LIA=n \
      CONFIG_TCP_CONG_OLIA=n \
      CONFIG_TCP_CONG_WVEGAS=n
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
