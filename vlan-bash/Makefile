include $(TOPDIR)/rules.mk

PKG_NAME:=vlan-bash
PKG_VERSION:=0.6
PKG_RELEASE:=0

include $(INCLUDE_DIR)/package.mk

MY_DEPENDS := overthebox python-swconfig-otb \
	luaposix luasec luasocket \
	getopt dmidecode tc iperf3 mtr bind-dig owipcalc ethtool \
	rng-tools ss strace tcpdump-mini \
	luci luci-lib-json luci-theme-bootstrap \
	libustream-mbedtls luci-lib-px5g px5g

MY_DEPENDS += kmod-fs-ext4 kmod-fs-hfsplus kmod-fs-vfat \
	fuse-utils luci-app-samba samba36-server \
	luci-app-statistics \
	bash htop bmon rsync netcat svfs screen

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
