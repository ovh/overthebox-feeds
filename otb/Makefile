include $(TOPDIR)/rules.mk

PKG_NAME:=otb
PKG_VERSION:=0.6
PKG_RELEASE:=33

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    otb-backup otb-diagnostics \
    otb-qos otb-dscp otb-remote \
    otb-tracker otb-autoroute otb-leds \
    TARGET_x86:python-swconfig-otb \
    usb-modeswitch bwm-ng screen \
    libimobiledevice usbmuxd \
    iptables-mod-trace kmod-ipt-raw \
    libustream-mbedtls luci-lib-px5g px5g  \
    tc iperf3 mtr rng-tools ss strace \
    tcpdump-mini conntrack conntrackd \
    luci luci-lib-json luci-app-overthebox \
    lsblk dnsmasq kmod-nf-nathelper \
    kmod-nf-nathelper-extra comgt luci-proto-3g \
    TARGET_x86:kmod-cherrytrail-gpio-powerbutton

define Package/$(PKG_NAME)
SECTION:=OVH
CATEGORY:=OverTheBox
DEPENDS:=$(foreach p,$(MY_DEPENDS),+$(p))
TITLE:=$(PKG_NAME)
PKGARCH:=all
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc
	echo "$(PKG_VERSION)-$(PKG_RELEASE)" > $(1)/etc/otb-version
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
