#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for the OverTheBox project
LUCI_DEPENDS:=+bandwidth +luci-mod-admin-full +luci-app-firewall +luci-lib-nixio +luci-theme-ovh +otb-qos +luci +luci-lib-px5g +luci-lib-json +luci-proto-3g

PKG_VERSION:=v1.21.1
PKG_RELEASE:=2

include ../luci/luci.mk

define Package/overthebox/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	# force clear luci cache
	rm -fr /tmp/luci-indexcache /tmp/luci-modulecache

	exit 0
fi
endef

# call BuildPackage - OpenWrt buildroot signature
