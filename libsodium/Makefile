#
# Copyright (C) 2009-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libsodium
PKG_VERSION:=1.0.11
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://download.libsodium.org/libsodium/releases
PKG_MD5SUM:=b58928d035064b2a46fb564937b83540

PKG_FIXUP:=libtool autoreconf
PKG_USE_MIPS16:=0
PKG_INSTALL:=1

PKG_MAINTAINER:=Damiano Renfer <damiano.renfer@gmail.com>
PKG_LICENSE:=ISC

include $(INCLUDE_DIR)/package.mk

define Package/libsodium
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=P(ortable|ackageable) NaCl-based crypto library
  URL:=https://github.com/jedisct1/libsodium
  MAINTAINER:=Damiano Renfer <damiano.renfer@gmail.com>
endef

define Package/libsodium/description
  Sodium is a modern, easy-to-use software library for encryption, decryption, signatures, password hashing and more.

  It is a portable, cross-compilable, installable, packageable fork of NaCl, with a compatible API, and an extended API to improve usability even further.
  Its goal is to provide all of the core operations needed to build higher-level cryptographic tools.
  Sodium supports a variety of compilers and operating systems, including Windows (with MinGW or Visual Studio, x86 and x86_64), iOS and Android.
  The design choices emphasize security, and "magic constants" have clear rationales.
  And despite the emphasis on high security, primitives are faster across-the-board than most implementations of the NIST standards.
endef

define Package/libsodium/config
menu "Configuration"
	depends on PACKAGE_libsodium
	config LIBSODIUM_MINIMAL
		bool "Compile only what is required for the high-level API, should be fine in most cases."
		default y
endmenu
endef

CONFIGURE_ARGS+= \
	--disable-ssp \
	$(if $(CONFIG_LIBSODIUM_MINIMAL),--enable-minimal=yes,--enable-minimal=no)

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/sodium
	$(CP) $(PKG_INSTALL_DIR)/usr/include/sodium.h $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/sodium/*.h $(1)/usr/include/sodium
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsodium.{a,so*} $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libsodium.pc $(1)/usr/lib/pkgconfig/
endef

define Package/libsodium/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsodium.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libsodium))
