include $(TOPDIR)/rules.mk

PKG_NAME:=otb-full
PKG_VERSION:=0.1
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    fuse-utils luci-app-samba samba36-server \
    rsync netcat svfs vim-full htop netdata \
    iputils-ping perf bmon

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
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
