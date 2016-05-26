#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mwan3otb
PKG_VERSION:=1.7
PKG_RELEASE:=22
PKG_MAINTAINER:=Jeroen Louwes <jeroen.louwes@gmail.com>
PKG_LICENSE:=GPLv2

include $(INCLUDE_DIR)/package.mk

define Package/mwan3otb
   SECTION:=net
   CATEGORY:=Network
   SUBMENU:=Routing and Redirection
   DEPENDS:=+ip +ipset +iptables +iptables-mod-conntrack-extra +iptables-mod-ipopt +lua-spcdns
   CONFLICTS:=mwan3
   TITLE:=Multiwan hotplug script with connection tracking support - overthebox version
   MAINTAINER:=Jeroen Louwes <jeroen.louwes@gmail.com>
   PKGARCH:=all
endef

define Package/mwan3otb/description
Hotplug script which makes configuration of multiple WAN interfaces simple
and manageable. With loadbalancing/failover support for up to 250 wan
interfaces, connection tracking and an easy to manage traffic ruleset.
endef

define Package/mwan3otb/conffiles
/etc/config/mwan3
endef

define Build/Compile
endef

define Package/mwan3otb/install
$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,mwan3otb))
