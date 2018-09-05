#
# Copyright (C) 2017 Lucian Cristian <lucian.cristian@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=frr
PKG_VERSION:=3.0
PKG_RELEASE:=1
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/FRRouting/frr.git
PKG_SOURCE_VERSION:=f633dc2998a8aa20d7206e40cddb714a91fb3c67
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_CONFIG_DEPENDS:= \
	CONFIG_IPV6 \
	CONFIG_PACKAGE_frr-watchfrr \
	CONFIG_PACKAGE_frr-zebra \
	CONFIG_PACKAGE_frr-libfrr \
	CONFIG_PACKAGE_frr-bgpd \
	CONFIG_PACKAGE_frr-ldpd \
	CONFIG_PACKAGE_frr-isisd \
	CONFIG_PACKAGE_frr-nhrpd \
	CONFIG_PACKAGE_frr-ospfd \
	CONFIG_PACKAGE_frr-ospf6d \
	CONFIG_PACKAGE_frr-pimd \
	CONFIG_PACKAGE_frr-ripd \
	CONFIG_PACKAGE_frr-ripngd \
	CONFIG_PACKAGE_frr-vtysh
PKG_BUILD_PARALLEL:=1
PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/frr/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  DEPENDS:=frr
  TITLE:=The FRRouting (FRR) Software Routing Suite
  URL:=https://www.frrouting.org/
  MAINTAINER:=Lucian Cristian <lucian.cristian@gmail.com>
endef

define Package/frr
  $(call Package/frr/Default)
  DEPENDS:=+librt
  MENU:=1
endef

define Package/frr/description
    FRRouting (FRR) is an IP routing protocol suite for Linux and Unix platforms which
    includes protocol daemons for BGP, IS-IS, LDP, OSPF, PIM, and RIP.
endef

define Package/frr-watchfrr
  $(call Package/frr/Default)
  TITLE:=frr watchdog
  DEPENDS+=+frr-libfrr
  DEFAULT:=y if PACKAGE_frr
endef

define Package/frr-zebra
  $(call Package/frr/Default)
  TITLE:=Zebra daemon
  DEPENDS+=+frr-libfrr
  DEFAULT:=y if PACKAGE_frr
endef

define Package/frr-libfrr
  $(call Package/frr/Default)
  TITLE:=zebra library
  DEPENDS+=+libjson-c
endef

define Package/frr-bgpd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr
  TITLE:=BGPv4, BGPv4+, BGPv4- routing engine
endef

define Package/frr-ldpd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr @BROKEN
  TITLE:=LDP routing engine
endef

define Package/frr-isisd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr
  TITLE:=IS-IS routing engine
endef

define Package/frr-nhrpd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr +libcares
  TITLE:=NHRP routing engine
endef

define Package/frr-ospfd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr
  TITLE:=OSPFv2 routing engine
endef

define Package/frr-ospf6d
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr @IPV6
  TITLE:=OSPFv3 routing engine
endef

define Package/frr-pimd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr
  TITLE:=PIM routing engine
endef

define Package/frr-ripd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr
  TITLE:=RIP routing engine
endef

define Package/frr-ripngd
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr @IPV6
  TITLE:=RIPNG routing engine
endef

define Package/frr-vtysh
  $(call Package/frr/Default)
  DEPENDS+=+frr-libfrr +libreadline +libncurses
  TITLE:=integrated shell for frr routing software
endef

define Package/frr-zebra/conffiles
/etc/frr/zebra.conf
endef

define Package/frr-bgpd/conffiles
/etc/frr/bgpd.conf
endef

define Package/frr-isisd/conffiles
/etc/frr/isisd.conf
endef

define Package/frr-ldpd/conffiles
/etc/frr/ldpd.conf
endef

define Package/frr-nhrpd/conffiles
/etc/frr/nhrpd.conf
endef

define Package/frr-ospfd/conffiles
/etc/frr/ospfd.conf
endef

define Package/frr-ospf6d/conffiles
/etc/frr/ospf6d.conf
endef

define Package/frr-pimd/conffiles
/etc/frr/pimd.conf
endef

define Package/frr-ripd/conffiles
/etc/frr/ripd.conf
endef

define Package/frr-ripngd/conffiles
/etc/frr/ripngd.conf
endef

ifneq ($(SDK),)
CONFIG_PACKAGE_frr-libfrr:=m
CONFIG_PACKAGE_frr-watchfrr:=m
CONFIG_PACKAGE_frr-zebra:=m
CONFIG_PACKAGE_frr-bgpd:=m
CONFIG_PACKAGE_frr-isisd:=m
CONFIG_PACKAGE_frr-ldpd:=m
CONFIG_PACKAGE_frr-nhrpd:=m
CONFIG_PACKAGE_frr-ospfd:=m
CONFIG_PACKAGE_frr-ospf6d:=m
CONFIG_PACKAGE_frr-pimd:=m
CONFIG_PACKAGE_frr-ripd:=m
CONFIG_PACKAGE_frr-ripngd:=m
CONFIG_PACKAGE_frr-vtysh:=m
endif

CONFIGURE_ARGS+= \
	--host="$(GNU_TARGET_NAME)" \
	CFLAGS="$(TARGET_CFLAGS)" \
	HOST_CFLAGS="$(BUILD_CFLAGS)" \
	BUILD_CPPFLAGS="$(TARGET_CPPLAGS)" \
	BUILD_CFLAGS="$(TARGET_CFLAGS)" \
	BUILD_LDFLAGS="$(TARGET_LDFLAGS)" \
	--localstatedir=/var/run/frr \
	--sysconfdir=/etc/frr/ \
	--enable-shared \
	--disable-static \
	--enable-user=network \
	--enable-group=network \
	--enable-multipath=8 \
	--disable-ospfclient \
	--disable-capabilities \
	--disable-doc \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-libfrr,zebra) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-bgpd,bgpd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-ldpd,ldpd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-isisd,isisd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-nhrpd,nhrpd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-ospfd,ospfd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-ospf6d,ospf6d) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-pimd,pimd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-ripd,ripd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-ripngd,ripngd) \
	$(call autoconf_bool,CONFIG_PACKAGE_frr-vtysh,vtysh) \

MAKE_FLAGS += \
	CFLAGS="$(TARGET_CFLAGS)" \
	CPPFLAGS="$(TARGET_CPPLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)"

define Package/frr/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/frr $(1)/usr/sbin/frr.init
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/frr.init $(1)/etc/init.d/frr
endef

define Package/frr-watchfrr/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/watchfrr $(1)/usr/sbin/
endef

define Package/frr-zebra/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/zebra $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/zebra.conf
endef

define Package/frr-bgpd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/bgpd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/bgpd.conf
endef

define Package/frr-isisd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/isisd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/isisd.conf
endef

define Package/frr-ldpd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/ldpd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/ldpd.conf
endef

define Package/frr-nhrpd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/nhrpd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/nhrpd.conf
endef

define Package/frr-ospfd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/ospfd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/ospfd.conf
endef

define Package/frr-ospf6d/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/ospf6d $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/ospf6d.conf
endef

define Package/frr-pimd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/pimd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/pimd.conf
endef

define Package/frr-ripd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/ripd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/ripd.conf
endef

define Package/frr-ripngd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/ripngd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/frr.conf $(1)/etc/frr/ripngd.conf
endef

define Package/frr-vtysh/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/vtysh $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/frr
	chmod 0750 $(1)/etc/frr
	$(INSTALL_CONF) ./files/vtysh.conf $(1)/etc/frr/
endef

define Package/frr-libfrr/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libfrr.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,frr))
$(eval $(call BuildPackage,frr-libfrr))
$(eval $(call BuildPackage,frr-watchfrr))
$(eval $(call BuildPackage,frr-zebra))
$(eval $(call BuildPackage,frr-bgpd))
$(eval $(call BuildPackage,frr-isisd))
$(eval $(call BuildPackage,frr-ldpd))
$(eval $(call BuildPackage,frr-nhrpd))
$(eval $(call BuildPackage,frr-ospfd))
$(eval $(call BuildPackage,frr-ospf6d))
$(eval $(call BuildPackage,frr-pimd))
$(eval $(call BuildPackage,frr-ripd))
$(eval $(call BuildPackage,frr-ripngd))
$(eval $(call BuildPackage,frr-vtysh))
