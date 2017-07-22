include $(TOPDIR)/rules.mk

PKG_NAME:=otb-qos
PKG_VERSION:=0.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := tc kmod-sched-core kmod-sched-connmark kmod-ifb iptables iptables-mod-ipopt iptables-mod-conntrack-extra ethtool

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=$(foreach p,$(MY_DEPENDS),+$(p))
TITLE:=$(PKG_NAME)
PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
OverTheBox QoS
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/dscp
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
