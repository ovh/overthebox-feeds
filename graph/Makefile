include $(TOPDIR)/rules.mk

PKG_NAME:=graph
PKG_VERSION:=0.1
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=base
CATEGORY:=Base system
DEPENDS:=+curl
TITLE:=OpenTSDB Graph
endef

define Package/$(PKG_NAME)/description
OpenTSDB daemon
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) ./files/bin $(1)/bin/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/config $(1)/etc/config/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/init $(1)/etc/init.d/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
