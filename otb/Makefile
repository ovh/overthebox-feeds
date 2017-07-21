include $(TOPDIR)/rules.mk

PKG_NAME:=otb
PKG_VERSION:=0.6
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := \
    otb-backup otb-diagnostics \
    otb-qos otb-remote otb-tracker \
    TARGET_x86:python-swconfig-otb \
    usb-modeswitch bmon bwm-ng \
    kmod-fs-ext4 kmod-fs-hfsplus kmod-fs-vfat \
    fuse-utils luci-app-samba samba36-server \
    rsync netcat svfs screen \
    iptables-mod-trace kmod-ipt-raw \
    libustream-mbedtls luci-lib-px5g px5g  \
    getopt tc iperf3 mtr ethtool rng-tools \
    ss strace tcpdump-mini conntrack conntrackd \
    luci luci-lib-json luci-app-overthebox \
    vim-full dnsmasq-full

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
	echo "$(PKG_VERSION)-$(PKG_RELEASE)+$(PKG_NAME)" > $(1)/etc/otb-version
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
