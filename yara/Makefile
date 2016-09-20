include $(TOPDIR)/rules.mk

PKG_NAME:=yara
PKG_VERSION:=3.5.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/VirusTotal/yara/archive/
PKG_MD5SUM:=7a3248719771ece845f2ef94b09732f2
PKG_CAT:=zcat
PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/yara
  SECTION:=utils
  CATEGORY:=Network
  TITLE:=The VirusTotal/yara utility
  URL:=http://virustotal.github.io/yara/
  DEPENDS=+libopenssl #+libmagic
endef

define Package/yara/description
 The Yara Rules tool.
endef

define Build/Prepare
  $(Build/Prepare/Default)
  wget -O rules.zip https://github.com/Yara-Rules/rules/archive/master.zip
  unzip rules.zip
  rm rules.zip
endef

CONFIGURE_ARGS += --with-crypto \
                  --prefix /usr #\
                # --enable-magic

define Package/yara/install
  $(CP) -r $(PKG_INSTALL_DIR)/. $(1)/
  libtool --finish /usr/lib
  mkdir -p $(1)/usr/share/yara-rules/
  $(CP) -r rules-master/. $(1)/usr/share/yara-rules/
endef

$(eval $(call BuildPackage,yara))
