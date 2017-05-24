include $(TOPDIR)/rules.mk

PKG_NAME:=swconfig
PKG_RELEASE:=100

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Switch configuration utility
  DEPENDS:=+swconfig-lede +swconfig-otb
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
