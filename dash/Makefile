include $(TOPDIR)/rules.mk

PKG_NAME:=dash
PKG_VERSION:=0.5.9.1
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://git.kernel.org/pub/scm/utils/dash/dash.git/snapshot

PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=base
CATEGORY:=Base system
TITLE:=$(PKG_NAME)
endef

TARGET_CFLAGS += -Wno-format-security

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/dash $(1)/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
