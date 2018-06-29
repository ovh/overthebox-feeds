/*
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	Copyright (C) 2012-2014 PIVA SOFTWARE (www.pivasoftware.com)
 *		Author: Mohamed Kallel <mohamed.kallel@pivasoftware.com>
 *		Author: Anis Ellouze <anis.ellouze@pivasoftware.com>
 *	Copyright (C) 2011-2012 Luka Perkov <freecwmp@lukaperkov.net>
 */

#ifndef _EASYCWMP_EASYCWMP_H__
#define _EASYCWMP_EASYCWMP_H__

#define NAME	PACKAGE_NAME
#define EASYCWMP_VERSION	PACKAGE_VERSION

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))
#define ARRAY_AND_SIZE(x) (x), ARRAY_SIZE(x)
#endif

#define FREE(x) do { free(x); x = NULL; } while (0);

#ifdef DEBUG
#define D(format, ...) fprintf(stderr, "%s(%d): " format, __func__, __LINE__, ## __VA_ARGS__)
#else
#define D(format, ...) no_debug(0, format, ## __VA_ARGS__)
#endif

#ifdef DEVEL
#define DD(format, ...) fprintf(stderr, "%s(%d):: " format, __func__, __LINE__, ## __VA_ARGS__)
#define DDF(format, ...) fprintf(stderr, format, ## __VA_ARGS__)
#else
#define DD(format, ...) no_debug(0, format, ## __VA_ARGS__)
#define DDF(format, ...) no_debug(0, format, ## __VA_ARGS__)
#endif

static inline void no_debug(int level, const char *fmt, ...)
{
}

enum start_event_enum {
	START_BOOT = 0x1,
	START_GET_RPC_METHOD = 0x2
};

void easycwmp_reload(void);
void easycwmp_notify(void);

#define TRACE(MESSAGE,args...) { \
  const char *A[] = {MESSAGE}; \
  printf("(TRACE: %s %s %d)  ",__FUNCTION__,__FILE__,__LINE__); \
  if(sizeof(A) > 0) \
	printf(*A,##args); \
  printf("%s\n", " "); \
  fflush(stdout); \
}

#endif

