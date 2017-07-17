include $(TOPDIR)/rules.mk

PKG_NAME:=simpletracker-tests
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Kevin Lanvin <kevin.lanvin@corp.ovh.com>

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
TITLE:=simpletracker-tests
DEPENDS:=+simpletracker
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
A module to test simpletracker
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
$(CP) ./files/* $(1)/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
chmod +x /usr/bin/simpletracker-tests/test-*.sh
chmod +x /usr/bin/simpletracker-tests/scripts/*.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
