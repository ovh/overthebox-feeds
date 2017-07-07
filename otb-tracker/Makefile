include $(TOPDIR)/rules.mk

PKG_NAME:=otb-tracker
PKG_VERSION:=0.1
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=+overthebox
TITLE:=OverTheBox tracker
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
OverTheBox tracker
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) otb-* $(1)/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
