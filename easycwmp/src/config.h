/*
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	Copyright (C) 2012-2014 PIVA SOFTWARE (www.pivasoftware.com)
 *		Author: Mohamed Kallel <mohamed.kallel@pivasoftware.com>
 *		Author: Anis Ellouze <anis.ellouze@pivasoftware.com>
 *	Copyright (C) 2011 Luka Perkov <freecwmp@lukaperkov.net>
 */

#ifndef _EASYCWMP_CONFIG_H__
#define _EASYCWMP_CONFIG_H__

#include <uci.h>
#include <time.h>

#include "easycwmp.h"

void config_exit(void);
void config_load(void);
int config_remove_event(char *event);
int config_check_acs_url(void);

#ifdef BACKUP_DATA_IN_CONFIG
int easycwmp_uci_init(void);
int easycwmp_uci_fini(void);
char *easycwmp_uci_get_value(char *package, char *section, char *option);
char *easycwmp_uci_set_value(char *package, char *section, char *option, char *value);
int easycwmp_uci_commit(void);
#endif

struct acs {
	char *url;
	char *username;
	char *password;
	bool periodic_enable;
	bool http100continue_disable;
	int  periodic_interval;
	time_t periodic_time;
	char *ssl_cert;
	char *ssl_cacert;
	bool ssl_verify;
};

struct local {
	char *ip;
	char *interface;
	char *port;
	char *username;
	char *password;
	char *ubus_socket;
	int logging_level;
	int cr_auth_type;
};

struct core_config {
	struct acs *acs;
	struct local *local;
};

enum auth_type_enum {
	AUTH_BASIC,
	AUTH_DIGEST
};

#define DEFAULT_CR_AUTH_TYPE AUTH_DIGEST;


extern struct core_config *config;

#endif

