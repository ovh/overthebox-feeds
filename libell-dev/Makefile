include $(TOPDIR)/rules.mk

PKG_NAME:=libell-dev
PKG_VERSION:=0.53
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://kernel.googlesource.com/pub/scm/libs/ell/ell.git/+archive
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=skip
PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=Embedded linux library
	URL:=https://kernel.googlesource.com/pub/scm/libs/ell/ell.git
endef

define Build/Prepare
	tar -C $(PKG_BUILD_DIR)/ -xf $(DL_DIR)/$(PKG_SOURCE)
	(cd $(PKG_BUILD_DIR); ./bootstrap)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_INSTALL_DIR)/* $(1)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libell*.so* $(1)/usr/lib
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

