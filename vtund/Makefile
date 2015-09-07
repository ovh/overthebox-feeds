#
# Copyright (C) 2015 OVH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=vtun
PKG_VERSION:=3.0.3
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=@SF/vtun
PKG_MD5SUM:=f3becf2a0270910a841060c08d1db824

include $(INCLUDE_DIR)/package.mk

define Package/vtund
        SECTION:=net
        CATEGORY:=Network
	DEPENDS:=+kmod-tun +VTUND_LZO:liblzo +VTUND_LZO:zlib +VTUND_SSL:libopenssl +USE_GLIBC:libbsd
	TITLE:=VPN tunneling daemon
	URL:=http://vtun.sourceforge.net
	SUBMENU:=VPN
	MENU:=1
endef

define Package/vtund/config
menu "Configuration"
        depends on PACKAGE_vtund

config VTUND_config

	depends on PACKAGE_vtund
	config VTUND_LZO
		bool "enable vtun compression"
		help
			vtun tunnels will be compressed
		default y

	config VTUND_SSL
		bool "enable vtun ssl encryption"
		help
			vtun tunnels will be encrypted
		default y
endmenu
endef

define Package/vtund/conffiles
/etc/vtund.conf
/etc/config/vtund
endef

CONFIGURE_ARGS += \
	$(if $(CONFIG_VTUND_LZO),--with-lzo-lib="$(STAGING_DIR)/usr/lib/",--disable-zlib) \
	$(if $(CONFIG_VTUND_LZO),--with-lzo-headers="$(STAGING_DIR)/usr/include/lzo",--disable-lzo) \
	$(if $(CONFIG_VTUND_SSL),--with-ssl-headers="$(STAGING_DIR)/usr/lib/",--disable-ssl) \

CONFIGURE_VARS += \
	LIBS="$(TARGET_LDFLAGS)" \
	$(if $(CONFIG_VTUND_LZO),LZO_HDR_DIR="$(STAGING_DIR)/usr/include/lzo") \
	$(if $(CONFIG_VTUND_SSL),BLOWFISH_HDR_DIR="$(STAGING_DIR)/usr/include/openssl") \
	$(if $(CONFIG_VTUND_SSL),SSL_HDR_DIR="$(STAGING_DIR)/usr/include/openssl") \

define Build/Compile
	$(call Build/Compile/Default,vtund)
endef

define Package/vtund/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/vtund.conf $(1)/etc/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/vtund.config $(1)/etc/config/vtund
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/vtund $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/vtund.init $(1)/etc/init.d/vtund
endef

$(eval $(call BuildPackage,vtund))
