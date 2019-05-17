include $(TOPDIR)/rules.mk

PKG_NAME:=otb-leds
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=OVH
  CATEGORY:=OverTheBox
  TITLE:=OverTheBox leds
  DEPENDS:=+otb-tracker
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  otb-leds changes the leds status of supported devices
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/otb/connectivity-change-hook.d
	$(INSTALL_BIN) bin $(1)/usr/share/otb/connectivity-change-hook.d/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
