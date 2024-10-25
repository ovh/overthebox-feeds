include $(TOPDIR)/rules.mk

PKG_NAME:=otb-auto-sqm
PKG_VERSION:=0.0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=OVH
	CATEGORY:=OverTheBox
	DEPENDS:=+jq +sqm-scripts
	TITLE:=Automatic SQM
endef

define Package/$(PKG_NAME)/description
	Overthebox auto-configure of SQM
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
