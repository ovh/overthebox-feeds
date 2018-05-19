include $(TOPDIR)/rules.mk

PKG_NAME:=otb-autoroute
PKG_VERSION:=1.7
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=OVH
  CATEGORY:=OverTheBox
  TITLE:=OverTheBox autoroute
  DEPENDS:=+otb-tracker +ip-full
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  otb-autoroute sets up the routes of the OTB
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/otb/post-tracking.d
	$(INSTALL_BIN) bin $(1)/usr/share/otb/post-tracking.d/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
