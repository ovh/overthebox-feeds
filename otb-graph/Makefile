include $(TOPDIR)/rules.mk

PKG_NAME:=otb-graph
PKG_VERSION:=1.0.0
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=base
CATEGORY:=Base system
DEPENDS:=+curl +overthebox
TITLE:=Provisioning Graph
endef

define Package/$(PKG_NAME)/description
Graph daemon
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) bin $(1)/bin/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	touch $(1)/etc/config/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
