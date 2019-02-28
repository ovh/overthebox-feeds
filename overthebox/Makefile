include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.67
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    graph glorytun glorytun-udp mptcp shadowsocks-libev  \
    kmod-macvlan jq curl ca-bundle ca-certificates \
    @LIBCURL_THREADED_RESOLVER

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=$(foreach p,$(MY_DEPENDS),+$(p))
TITLE:=OverTheBox
endef

define Package/$(PKG_NAME)/description
OverTheBox package
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
	$(INSTALL_DIR) $(1)/etc/config
	touch $(1)/etc/config/$(PKG_NAME)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
