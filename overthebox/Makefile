include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=1.3.19
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    glorytun mptcp mptcpd shadowsocks-rust otb-graph \
    kmod-macvlan jq curl ca-bundle ca-certificates iperf3 \
	librespeed-cli \
    TARGET_x86:otb-v2b TARGET_x86:otb-v2c \
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
