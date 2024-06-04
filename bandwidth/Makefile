include $(TOPDIR)/rules.mk

PKG_NAME:=bandwidth
PKG_VERSION:=1.0.1
PKG_RELEASE=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=net
CATEGORY:=Network
TITLE:=Bandwidth Monitoring
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Lightweight Bandwidth Monitoring by MAC
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
