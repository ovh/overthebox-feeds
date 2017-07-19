include $(TOPDIR)/rules.mk

PKG_NAME:=overthebox
PKG_VERSION:=0.6
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := graph dnsmasq-full glorytun glorytun-udp luci-app-overthebox \
	mptcp shadowsocks-libev luaposix luasec luasocket file \
	getopt tc iperf3 mtr bind-dig owipcalc ethtool \
	rng-tools ss strace tcpdump-mini conntrack conntrackd \
	luci luci-lib-json ca-certificates \
	libustream-mbedtls luci-lib-px5g px5g ip-full \
	curl ca-bundle jq

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
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
