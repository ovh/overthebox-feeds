include $(TOPDIR)/rules.mk

PKG_NAME:=otb
PKG_VERSION:=0.6
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := overthebox TARGET_x86:python-swconfig-otb

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=$(foreach p,$(MY_DEPENDS),+$(p))
TITLE:=$(PKG_NAME)
PKGARCH:=all
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc
	echo "$(PKG_VERSION)-$(PKG_RELEASE)+$(PKG_NAME)" > $(1)/etc/otb-version
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
