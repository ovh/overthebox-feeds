include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=otb-v2ab-pwrbtn
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/sduponch/cherrytrail-gpio-powerbutton.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE)
PKG_SOURCE_VERSION:=0e6332a5957559f404bf6d417469e75546831c2a
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.xz

PKG_LICENSE:=GPLv3
PKG_MAINTAINER:=DUPONCHEEL Sébastien <sebastien.duponcheel@corp.ovh.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE)

include $(INCLUDE_DIR)/package.mk

define KernelPackage/otb-v2ab-pwrbtn
  TITLE:=OverTheBox V2ab power button support
  DEPENDS:=@TARGET_x86
  FILES:=\
	$(LINUX_DIR)/drivers/pinctrl/intel/pinctrl-cherryview.ko \
	$(PKG_BUILD_DIR)/cherrytrail-gpio-powerbutton.ko
  KCONFIG:= \
	CONFIG_X86_INTEL_LPSS=y \
	CONFIG_PINCTRL_CHERRYVIEW=m
  AUTOLOAD:=$(call AutoLoad,50,pinctrl-cherryview cherrytrail-gpio-powerbutton)
  MAINTAINER:=DUPONCHEEL Sébastien <sebastien.duponcheel@corp.ovh.com>
endef

MAKE_OPTS:= \
        ARCH="$(LINUX_KARCH)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        SUBDIRS="$(PKG_BUILD_DIR)" \
        EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
        $(EXTRA_KCONFIG)

define Build/Compile
   +$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" $(MAKE_OPTS) M=$(PKG_BUILD_DIR) modules
endef

$(eval $(call KernelPackage,otb-v2ab-pwrbtn))
