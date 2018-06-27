bin_PROGRAMS = easycwmpd

easycwmpd_SOURCES =		\
	../src/backup.c		\
	../src/backup.h		\
	../src/config.h		\
	../src/config.c		\
	../src/cwmp.h		\
	../src/cwmp.c		\
	../src/digestauth.h	\
	../src/digestauth.c	\
	../src/external.h	\
	../src/external.c	\
	../src/easycwmp.h	\
	../src/easycwmp.c	\
	../src/http.h		\
	../src/http.c		\
	../src/json.c		\
	../src/json.h		\
	../src/log.c		\
	../src/log.h		\
	../src/md5.h		\
	../src/md5.c		\
	../src/time.h		\
	../src/time.c		\
	../src/ubus.h		\
	../src/ubus.c		\
	../src/xml.h		\
	../src/xml.c       	\
	../src/base64.h		\
	../src/base64.c		\
	../src/basicauth.h  	\
	../src/basicauth.c

easycwmpd_CFLAGS =		\
	$(AM_CFLAGS)		\
	$(LIBUCI_CFLAGS)	\
	$(LIBUBOX_CFLAGS)	\
	$(LIBUBUS_CFLAGS)	\
	$(MICROXML_CFLAGS)	\
	$(LIBCURL_CFLAGS)

easycwmpd_LDFLAGS =		\
	$(AM_LDFLAGS)		\
	$(LIBUCI_LDFLAGS)	\
	$(LIBUBOX_LDFLAGS)	\
	$(LIBUBUS_LDFLAGS)	\
	$(MICROXML_LDFLAGS)	\
	$(LIBCURL_LDFLAGS)

easycwmpd_LDADD =		\
	$(AM_LIBS)			\
	$(LIBUCI_LIBS)		\
	$(LIBUBOX_LIBS)		\
	$(LIBUBUS_LIBS)		\
	$(MICROXML_LIBS)	\
	$(LIBCURL_LIBS)		\
	$(LIBJSON_LIBS)

