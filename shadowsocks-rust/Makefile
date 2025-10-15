include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-rust
PKG_VERSION:=1.23.5
PKG_RELEASE:=1

PKG_SOURCE:=shadowsocks-v$(PKG_VERSION).$(ARCH)-unknown-linux-musl.tar.xz
PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-rust/releases/download/v$(PKG_VERSION)/
PKG_HASH:=skip

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Lightweight Secured Socks5 Proxy - Rust
	URL:=https://github.com/shadowsocks/shadowsocks-rust
	DEPENDS:=
endef

define Package/$(PKG_NAME)/description
Shadowsocks-Rust is a fast and secure socks5 proxy.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	tar -C $(PKG_BUILD_DIR) -Jxf $(DL_DIR)/$(PKG_SOURCE)
endef

define Build/Compile
	echo "Skipping compilation as we are using prebuilt binaries."
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
	
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ssserver $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sslocal $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ssservice $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ssurl $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/config
	touch $(1)/etc/config/shadowsocks
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
