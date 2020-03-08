include $(TOPDIR)/rules.mk

PKG_NAME:=otb
PKG_VERSION:=0.7
PKG_RELEASE:=3

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    otb-backup otb-diagnostics otb-remote \
    otb-tracker otb-luci ip-full \
    TARGET_x86:python-swconfig-otb \
    TARGET_x86:kmod-cherrytrail-gpio-powerbutton \
    usb-modeswitch libimobiledevice usbmuxd \
    iptables-mod-trace kmod-ipt-raw \
    rng-tools conntrack conntrackd \
    dnsmasq kmod-nf-nathelper \
    kmod-nf-nathelper-extra comgt

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
