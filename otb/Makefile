include $(TOPDIR)/rules.mk

PKG_NAME:=otb
PKG_VERSION:=0.7
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    otb-backup otb-diagnostics \
    otb-qos otb-dscp otb-remote \
    otb-tracker otb-luci ip-full \
    TARGET_x86:python-swconfig-otb \
    usb-modeswitch bwm-ng screen \
    libimobiledevice usbmuxd \
    iptables-mod-trace kmod-ipt-raw \
    mtr rng-tools ss strace \
    tcpdump-mini conntrack conntrackd \
    dnsmasq-full kmod-nf-nathelper \
    kmod-nf-nathelper-extra comgt \
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
