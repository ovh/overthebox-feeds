include $(TOPDIR)/rules.mk

PKG_NAME:=otb-qos
PKG_VERSION:=0.11
PKG_RELEASE:=1

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
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/usr/share/otb/connectivity-change-hook.d
	$(INSTALL_BIN) connectivity-change-hook.d/* $(1)/usr/share/otb/connectivity-change-hook.d
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) otb-cake-parser $(1)/bin/otb-cake-parser
	$(INSTALL_BIN) bin $(1)/bin/${PKG_NAME}
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
