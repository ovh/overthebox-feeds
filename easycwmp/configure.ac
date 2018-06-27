AC_INIT([easycwmpd], [1.7.0], [mohamed.kallel@pivasoftware.com])
AM_INIT_AUTOMAKE
AC_CONFIG_SRCDIR([src/easycwmp.c])

AM_INIT_AUTOMAKE([subdir-objects])

AC_ARG_ENABLE(jsonc, [AS_HELP_STRING([--enable-jsonc], [build with jsonc])], [
 AC_DEFINE(JSONC)
 LIBJSON_LIBS='-ljson-c'
 AC_SUBST([LIBJSON_LIBS])
], [
 LIBJSON_LIBS='-ljson'
 AC_SUBST([LIBJSON_LIBS])
])

AC_ARG_ENABLE(debug, [AS_HELP_STRING([--enable-debug], [enable debugging messages])], AC_DEFINE(DEBUG),)
AC_ARG_ENABLE(devel, [AS_HELP_STRING([--enable-devel], [enable development messages])], AC_DEFINE(DEVEL),)
AC_ARG_ENABLE(backupdatainconfig, [AS_HELP_STRING([--enable-backupdatainconfig], [enable backup data saved in the config])], AC_DEFINE(BACKUP_DATA_IN_CONFIG),)

# checks for programs
AC_PROG_CC
AM_PROG_CC_C_O

# checks for libraries

AC_ARG_WITH([uci-include-path],
  [AS_HELP_STRING([--with-uci-include-path],
    [location of the uci library headers])],
  [LIBUCI_CFLAGS="-I$withval"])
AC_SUBST([LIBUCI_CFLAGS])

AC_ARG_WITH([uci-lib-path],
  [AS_HELP_STRING([--with-uci-lib-path], [location of the uci library])], [LIBUCI_LDFLAGS="-L$withval"])
AC_SUBST([LIBUCI_LDFLAGS])

LIBUCI_LIBS='-luci'
AC_SUBST([LIBUCI_LIBS])

AC_ARG_WITH([libubox-include-path],
  [AS_HELP_STRING([--with-libubox-include-path],
    [location of the libubox library headers])],
  [LIBUBOX_CFLAGS="-I$withval"])
AC_SUBST([LIBUBOX_CFLAGS])

AC_ARG_WITH([libubox-lib-path],
  [AS_HELP_STRING([--with-libubox-lib-path], [location of the libubox library])], [LIBUBOX_LDFLAGS="-L$withval"])
AC_SUBST([LIBUBOX_LDFLAGS])

LIBUBOX_LIBS='-lubox'
AC_SUBST([LIBUBOX_LIBS])

AC_ARG_WITH([libubus-include-path],
  [AS_HELP_STRING([--with-libubus-include-path],
    [location of the libubus library headers])],
  [LIBUBUS_CFLAGS="-I$withval"])
AC_SUBST([LIBUBUS_CFLAGS])

AC_ARG_WITH([libubus-lib-path],
  [AS_HELP_STRING([--with-libubus-lib-path], [location of the libubus library])], [LIBUBUS_LDFLAGS="-L$withval"])
AC_SUBST([LIBUBUS_LDFLAGS])

LIBUBUS_LIBS='-lubus'
AC_SUBST([LIBUBUS_LIBS])

PKG_CHECK_MODULES(LIBCURL, [libcurl])
AC_SUBST(LIBCURL_CFLAGS)
AC_SUBST(LIBCURL_LDFLAGS)
AC_SUBST(LIBCURL_LIBS)

PKG_CHECK_MODULES(MICROXML, [microxml])
AC_SUBST(MICROXML_CFLAGS)
AC_SUBST(MICROXML_LDFLAGS)
AC_SUBST(MICROXML_LIBS)

# checks for header files
AC_CHECK_HEADERS([stdlib.h string.h])

# checks for typedefs, structures, and compiler characteristics
AC_TYPE_UINT8_T

# Makefiles
AC_CONFIG_FILES([
Makefile
bin/Makefile
])

AC_OUTPUT
