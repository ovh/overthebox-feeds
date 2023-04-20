include $(TOPDIR)/rules.mk

PKG_NAME:=otb-tracker
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=OVH
  CATEGORY:=OverTheBox
  TITLE:=OverTheBox tracker
  DEPENDS:=+overthebox +bind-dig
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  A module to track OTB connections
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) bin $(1)/bin/otb-tracker
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/usr/share/otb/post-tracking.d
	$(INSTALL_BIN) post-tracking.d/* $(1)/usr/share/otb/post-tracking.d
	$(INSTALL_DIR) $(1)/usr/share/otb/connectivity-change-hook.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) config $(1)/etc/config/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
