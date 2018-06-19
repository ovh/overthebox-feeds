include $(TOPDIR)/rules.mk

PKG_NAME:=otb-full
PKG_VERSION:=0.1
PKG_RELEASE:=6

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    fuse-utils luci-app-samba samba36-server \
    rsync netcat vim-full htop \
    iputils-ping bmon ethtool sysstat pciutils \
    mini_snmpd openvpn-openssl luci-app-openvpn \
    gdb

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
