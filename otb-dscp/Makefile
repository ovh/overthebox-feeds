include $(TOPDIR)/rules.mk

PKG_NAME:=otb-dscp
PKG_VERSION:=0.11.0
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
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/usr/share/otb/connectivity-change-hook.d
	$(INSTALL_BIN) connectivity-change-hook.d/* $(1)/usr/share/otb/connectivity-change-hook.d
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) reset $(1)/bin/otb-dscp-reset
	$(INSTALL_BIN) bin $(1)/bin/${PKG_NAME}
	$(INSTALL_DIR) $(1)/etc/config
	./reset $(1)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
