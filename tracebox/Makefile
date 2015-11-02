include $(TOPDIR)/rules.mk

PKG_NAME:=tracebox
PKG_VERSION:=0.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=git@github.com:tracebox/tracebox.git
PKG_MAINTAINER:=Gregory Detal <gregory.detal@uclouvain.be>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=v0.2

include $(INCLUDE_DIR)/uclibc++.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/autotools.mk

define Package/tracebox
  SECTION:=net
  CATEGORY:=Network
  TITLE:=tracebox
  DEPENDS:=+liblua +libpcap +libpthread +librt $(CXX_DEPENDS)
endef

define Package/tracebox/description
  Tracebox is a tool that allows to detect middleboxes on any paths, i.e.,
between a source and any destination. Tracebox can be viewed as a tool similar
to traceroute as it uses ICMP replies to identify changes in the packets.
endef

CONFIGURE_VARS += \
	ac_cv_header_lua_h=no \
	ax_header_version_match=yes

CONFIGURE_ARGS += \
	--with-libpcap=$(STAGING_DIR)/usr

EXTRA_CPPFLAGS += -fpermissive

define Build/Prepare
	$(call Build/Prepare/Default)
	touch $(PKG_BUILD_DIR)/config.h.in
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR); AUTOHEADER=true autoreconf --install)
	$(call Build/Configure/Default)
endef


define Package/tracebox/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tracebox/tracebox $(1)/usr/sbin/tracebox
endef

$(eval $(call BuildPackage,tracebox))
