include $(TOPDIR)/rules.mk

PKG_NAME:=otb-backup
PKG_VERSION:=0.2.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=+overthebox +file
TITLE:=OverTheBox backup
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
OverTheBox backup system
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
