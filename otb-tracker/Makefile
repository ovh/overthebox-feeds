include $(TOPDIR)/rules.mk

PKG_NAME:=otb-tracker
PKG_VERSION:=2.3.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=OVH
  CATEGORY:=OverTheBox
  TITLE:=OverTheBox tracker
  DEPENDS:=+overthebox +bind-dig
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  A module to track OTB connections
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
