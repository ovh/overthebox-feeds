include $(TOPDIR)/rules.mk

PKG_NAME:=otb-v2c
PKG_VERSION:=0.1
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
	kmod-leds-gpio kmod-leds-apu kmod-pcengines-apuv2 \
	kmod-crypto-hw-ccp amd64-microcode \

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
TITLE:=$(PKG_NAME)
DEPENDS:=$(foreach p,$(MY_DEPENDS),+$(p))
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
