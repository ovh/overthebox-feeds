include $(TOPDIR)/rules.mk

PKG_NAME:=sticky
PKG_VERSION:=0.6
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=+overthebox
TITLE:=sticky
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
sticky
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc
	echo "$(PKG_VERSION)-$(PKG_RELEASE)+$(PKG_NAME)" > $(1)/etc/otb-version
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
