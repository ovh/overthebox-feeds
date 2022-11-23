include $(TOPDIR)/rules.mk

PKG_NAME:=otb-qos
PKG_VERSION:=0.12.0
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := kmod-sched-cake tc otb-dscp

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
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
