#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-theme-ovh
PKG_VERSION:=v0.5
PKG_RELEASE:=0
PKG_LICENSE:=GPLv2

include $(INCLUDE_DIR)/package.mk

define Package/luci-theme-ovh
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=OVH Theme
  PKGARCH:=all
  SUBMENU:=4. Themes
endef

define Package/luci-theme-ovh/description
	Overthebox Theme by OVH
endef

define Build/Compile
endef

define Package/luci-theme-ovh/install
	$(CP) ./root/* $(1)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/www
	$(CP) ./htdocs/* $(1)/www
endef

define Package/luci-theme-ovh/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	(. /etc/uci-defaults/luci-theme-ovh) && rm -f /etc/uci-defaults/luci-theme-ovh
	exit 0
}
endef


$(eval $(call BuildPackage,luci-theme-ovh))

