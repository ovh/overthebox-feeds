include $(TOPDIR)/rules.mk

PKG_NAME:=otb-dscp
PKG_VERSION:=0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=+overthebox +jq +curl
TITLE:=OverTheBox DSCP
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
OverTheBox DSCP
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/dscp
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/dscp
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) config $(1)/etc/config/dscp
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
