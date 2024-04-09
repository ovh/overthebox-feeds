#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
# Copyright (C) 2014-2023 OVHcloud <contact@ovhcloud.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI OverTheBox - Global System settings
LUCI_DEPENDS:=+bandwidth +luci-mod-admin-full +luci-app-firewall +luci-lib-nixio +luci-theme-bootstrap +otb-qos +luci +luci-lib-px5g +luci-lib-json +luci-proto-3g +luci-compat \
	      +luci-app-sqm +luci-app-statistics

PKG_VERSION:=v1.0.0
PKG_RELEASE:=1

define Package/luci-mod-overthebox/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || /etc/init.d/rpcd reload
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
