#
# Copyright (C) 2015 OpenWrt-dist
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-libev
PKG_VERSION:=2.5.0-1-ovh-2
PKG_RELEASE:=2
PKG_SOURCE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/ovh/overthebox-shadowsocks-libev/archive

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Max Lv <max.c.lv@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1
UNPACK_CMD=mkdir -p $(1) && tar xf "$(DL_DIR)/$(PKG_SOURCE)" -C $(1) --strip-components=1

include $(INCLUDE_DIR)/package.mk

define Package/shadowsocks-libev/Default
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Lightweight Secured Socks5 Proxy $(2)
	URL:=https://github.com/shadowsocks/shadowsocks-libev
	VARIANT:=$(1)
	DEPENDS:=$(3)
endef

Package/shadowsocks-libev = $(call Package/shadowsocks-libev/Default,openssl,(OpenSSL),+libopenssl +libpthread)
Package/shadowsocks-libev-spec = $(call Package/shadowsocks-libev/Default,openssl,(OpenSSL),+libopenssl +libpthread +ipset +ip +iptables-mod-tproxy)
Package/shadowsocks-libev-polarssl = $(call Package/shadowsocks-libev/Default,polarssl,(PolarSSL),+libpolarssl +libpthread)
Package/shadowsocks-libev-spec-polarssl = $(call Package/shadowsocks-libev/Default,polarssl,(PolarSSL),+libpolarssl +libpthread +ipset +ip +iptables-mod-tproxy)

define Package/shadowsocks-libev/description
Shadowsocks-libev is a lightweight secured scoks5 proxy for embedded devices and low end boxes.
endef

Package/shadowsocks-libev-spec/description = $(Package/shadowsocks-libev/description)
Package/shadowsocks-libev-polarssl/description = $(Package/shadowsocks-libev/description)
Package/shadowsocks-libev-spec-polarssl/description = $(Package/shadowsocks-libev/description)

define Package/shadowsocks-libev/conffiles
/etc/config/shadowsocks
/etc/shadowsocks.json
endef

define Package/shadowsocks-libev-spec/conffiles
/etc/shadowsocks/config.json
/etc/shadowsocks/ignore.list
endef

Package/shadowsocks-libev-polarssl/conffiles = $(Package/shadowsocks-libev/conffiles)
Package/shadowsocks-libev-spec-polarssl/conffiles = $(Package/shadowsocks-libev-spec/conffiles)

define Package/shadowsocks-libev-spec/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocks
		set firewall.shadowsocks=include
		set firewall.shadowsocks.type=script
		set firewall.shadowsocks.path=/usr/share/shadowsocks/firewall.include
		set firewall.shadowsocks.reload=1
		commit firewall
EOF
fi
exit 0
endef

Package/shadowsocks-libev-spec-polarssl/postinst = $(Package/shadowsocks-libev-spec/postinst)

ifeq ($(BUILD_VARIANT),polarssl)
	CONFIGURE_ARGS += --with-crypto-library=polarssl
endif

CONFIGURE_ARGS += --disable-documentation

define Package/shadowsocks-libev/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-{local,redir,tunnel} $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_CONF) ./files/shadowsocks.conf $(1)/etc/shadowsocks.json
	$(INSTALL_DIR) $(1)/etc/config
	touch  $(1)/etc/config/shadowsocks
	$(INSTALL_BIN) ./files/shadowsocks.init $(1)/etc/init.d/shadowsocks
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) ./files/shadowsocks.hotplug $(1)/etc/hotplug.d/iface/40-shadowsocks
endef

define Package/shadowsocks-libev/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/shadowsocks stop
	killall ss-redir 2> /dev/null
	killall ss-local 2> /dev/null
	killall ss-tunnel 2> /dev/null
	/etc/init.d/shadowsocks start
fi
exit 0
endef

define Package/shadowsocks-libev-spec/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-{redir,tunnel} $(1)/usr/bin
	$(INSTALL_BIN) ./files/shadowsocks.rule $(1)/usr/bin/ss-rules
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks.config $(1)/etc/config/shadowsocks
	$(INSTALL_DIR) $(1)/etc/shadowsocks
	$(INSTALL_CONF) ./files/shadowsocks.conf $(1)/etc/shadowsocks/config.json
	$(INSTALL_CONF) ./files/shadowsocks.list $(1)/etc/shadowsocks/ignore.list
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks.spec $(1)/etc/init.d/shadowsocks
	$(INSTALL_DIR) $(1)/usr/share/shadowsocks
	$(INSTALL_DATA) ./files/shadowsocks.include $(1)/usr/share/shadowsocks/firewall.include
	$(INSTALL_BIN) ./files/shadowsocks.track $(1)/usr/bin/ss-redir-track
endef

Package/shadowsocks-libev-polarssl/install = $(Package/shadowsocks-libev/install)
Package/shadowsocks-libev-spec-polarssl/install = $(Package/shadowsocks-libev-spec/install)

$(eval $(call BuildPackage,shadowsocks-libev))
$(eval $(call BuildPackage,shadowsocks-libev-spec))
$(eval $(call BuildPackage,shadowsocks-libev-polarssl))
$(eval $(call BuildPackage,shadowsocks-libev-spec-polarssl))
