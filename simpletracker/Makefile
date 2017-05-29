include $(TOPDIR)/rules.mk

PKG_NAME:=simpletracker
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Kevin Lanvin <kevin.lanvin@corp.ovh.com>
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=OVH
  CATEGORY:=OverTheBox
  TITLE:=simpletracker
  DEPENDS:=+bind-dig
  PKGARCH:=all 
endef

define Package/$(PKG_NAME)/description
	A module to track OTB connections
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
