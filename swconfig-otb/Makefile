include $(TOPDIR)/rules.mk

PKG_NAME:=python-swconfig-otb
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Martin Wetterwald <martin.wetterwald@corp.ovh.com>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk
$(call include_mk, python-package.mk)

define Package/python-swconfig-otb
  SUBMENU:=Python
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Tools to manage OVH OverTheBox switches
  DEPENDS:=+python-light +python-setuptools +python-logging +python-pyserial +lsof
endef

define Package/python-swconfig-otb/description
	A python module to manage OVH OverTheBox switches
endef

define Build/Prepare
	$(CP) ./files/* $(PKG_BUILD_DIR)
endef

define Build/Compile
	$(call Build/Compile/PyMod,, \
		install --no-compile --prefix="/usr" --root=$(PKG_INSTALL_DIR), \
	)
endef

define Package/python-swconfig-otb/install
	$(INSTALL_DIR) $(1)$(PYTHON_PKG_DIR)
	$(CP) $(PKG_INSTALL_DIR)$(PYTHON_PKG_DIR)/* $(1)$(PYTHON_PKG_DIR)

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/lib/network
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/swconfig.py $(1)/usr/bin/swconfig
	$(CP) $(PKG_BUILD_DIR)/switch.sh $(1)/lib/network/
endef

$(eval $(call BuildPackage,python-swconfig-otb))
