include $(TOPDIR)/rules.mk

PKG_NAME:=otb-dscp
PKG_VERSION:=1.1.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := overthebox iptables-mod-ipopt

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=$(foreach p,$(MY_DEPENDS),+$(p))
TITLE:=OverTheBox DSCP
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
OverTheBox DSCP
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/dscp
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
	./files/bin/otb-dscp-reset $(1)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
