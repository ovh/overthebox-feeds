include $(TOPDIR)/rules.mk

PKG_NAME:=otb-diagnostics
PKG_VERSION:=0.8.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=+overthebox +bind-dig +mtr +lsof +TARGET_x86:dmidecode +tc +lsblk
TITLE:=OverTheBox diagnostics
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
OverTheBox diagnostics
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
