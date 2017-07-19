include $(TOPDIR)/rules.mk

PKG_NAME:=svfs
PKG_VERSION:=0.9.1
PKG_RELEASE:=1

PKG_SOURCE:=svfs-linux-amd64
PKG_SOURCE_URL:=https://github.com/ovh/svfs/releases/download/v$(PKG_VERSION)

PKG_MAINTAINER:=Bash <bash@ovh.net>

include $(INCLUDE_DIR)/package.mk

define Package/svfs
SECTION:=net
CATEGORY:=Network
SUBMENU:=Filesystem
TITLE:=The Swift Virtual File System
DEPENDS:=+fuse-utils @TARGET_x86_64
endef

define Package/svfs/description
The Swift Virtual File System
endef

define Build/Prepare
	cp $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/svfs
	strip -s $(PKG_BUILD_DIR)/svfs
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/svfs/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/svfs $(1)/usr/bin
endef

$(eval $(call BuildPackage,svfs))
