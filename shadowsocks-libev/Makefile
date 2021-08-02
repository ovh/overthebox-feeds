#
# Copyright (C) 2015 OpenWrt-dist
# Copyright (C) 2014-2017 Jian Chang <aa65535@live.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-libev

PKG_SOURCE_PROTO=git
PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-libev.git
PKG_SOURCE_VERSION:=abcf85e98300762e4f31953cecf635ab182ef859

PKG_LICENSE:=GPL-3.0+

PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
TITLE:=Lightweight Secured Socks5 Proxy
SECTION:=net
CATEGORY:=Network
URL:=https://github.com/shadowsocks/shadowsocks-libev
DEPENDS:=+libcares +libev +libmbedtls +libpcre +libpthread +libsodium +ipset +ip +iptables-mod-tproxy
endef

define Package/$(PKG_NAME)/description
Shadowsocks-libev is a lightweight secured socks5 proxy for embedded devices and low end boxes.
endef

CONFIGURE_ARGS += --disable-documentation --disable-ssp --disable-assert

define Package/$(PKG_NAME)/conffiles
/etc/config/shadowsocks
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-redir $(1)/usr/bin
	$(INSTALL_BIN) ./files/shadowsocks.track $(1)/usr/bin/ss-redir-track
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks.init $(1)/etc/init.d/shadowsocks
	$(INSTALL_DIR) $(1)/etc/config
	touch  $(1)/etc/config/shadowsocks
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
