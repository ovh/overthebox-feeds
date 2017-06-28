include $(TOPDIR)/rules.mk

PKG_NAME:=jq
PKG_VERSION:=1.5
PKG_RELEASE:=0
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/stedolan/jq/releases/download/$(PKG_NAME)-$(PKG_VERSION)

PKG_FIXUP:=autoreconf -i
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
TITLE:=$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/jq $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
