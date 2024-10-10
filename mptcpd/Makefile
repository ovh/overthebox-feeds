include $(TOPDIR)/rules.mk

PKG_NAME:=mptcpd
PKG_VERSION:=0.12
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/multipath-tcp/mptcpd/releases/download/v$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=0507d497383b773a168cd35f4680b41894fcd8d941cb6619800a8e2bed831cbe
PKG_FIXUP:=autoreconf
PKG_FORTIFY_SOURCE:=0
PKG_BUILD_DEPENDS:=!USE_GLIBC:argp-standalone
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Multipath TCP Deamon
	DEPENDS:=+libell-dev
	URL:=https://github.com/multipath-tcp/mptcpd
endef

define Package/$(PKG_NAME)/conffiles
/etc/mptcpd/mptcpd.conf
endef

define Package/$(PKG_NAME)/description
	The Multipath TCP Daemon - mptcpd - is a daemon for Linux based operating systems
	that performs multipath TCP path management related operations in the user space.
	It interacts with the Linux kernel through a generic netlink connection
	to track per-connection information (e.g. available remote addresses),
	available network interfaces, request new MPTCP subflows, handle requests for subflows, etc.
endef

define Build/Configure
	$(call Build/Configure/Default, --with-kernel=upstream --disable-stack-protection)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_INSTALL_DIR)/usr/bin/mptcpd $(1)/usr/bin/mptcpd
	$(CP) $(PKG_INSTALL_DIR)/usr/bin/mptcpize $(1)/usr/bin/mptcpize

	$(INSTALL_DIR) $(1)/usr/include/mptcpd
	$(CP) $(PKG_INSTALL_DIR)/usr/include/mptcpd/*.h $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib/mptcpd
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/* $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/mptcpd/* $(1)/usr/lib/mptcpd/

	$(INSTALL_DIR) $(1)/etc/mptcpd
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/etc/mptcpd.conf $(1)/etc/mptcpd/mptcpd.conf
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
