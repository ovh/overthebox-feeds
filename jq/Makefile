include $(TOPDIR)/rules.mk

PKG_NAME:=jq
PKG_VERSION:=1.5
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/stedolan/jq/releases/download/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=c4d2bfec6436341113419debf479d833692cc5cdab7eb0326b5a4d4fbe9f493c
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=base
CATEGORY:=Base system
TITLE:=$(PKG_NAME)
endef

CONFIGURE_ARGS += --disable-maintainer-mode --disable-docs

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/jq $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
