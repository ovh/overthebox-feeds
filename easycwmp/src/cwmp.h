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

#ifndef _EASYCWMP_CWMP_H__
#define _EASYCWMP_CWMP_H__

#include <libubox/uloop.h>
#include <microxml.h>

#define MAX_DOWNLOAD 10
#define FAULT_ACS_8005 8005

enum END_SESSION {
	ENDS_REBOOT = 0x01,
	ENDS_FACTORY_RESET = 0x02,
	ENDS_RELOAD_CONFIG = 0x04,
};

enum EVENT_TYPE {
	EVENT_SINGLE,
	EVENT_MULTIPLE
};

enum EVENT_BACKUP_SAVE {
	EVENT_NO_BACKUP = 0,
	EVENT_BACKUP
};

enum EVENT_REMOVE_POLICY {
	EVENT_REMOVE_AFTER_INFORM = 0x1,
	EVENT_REMOVE_AFTER_TRANSFER_COMPLETE = 0x2,
	EVENT_REMOVE_NO_RETRY = 0x4
};

enum {
	EVENT_BOOTSTRAP = 0,
	EVENT_BOOT,
	EVENT_PERIODIC,
	EVENT_SCHEDULED,
	EVENT_VALUE_CHANGE,
	EVENT_KICKED,
	EVENT_CONNECTION_REQUEST,
	EVENT_TRANSFER_COMPLETE,
	EVENT_DIAGNOSTICS_COMPLETE,
	EVENT_REQUEST_DOWNLOAD,
	EVENT_AUTONOMOUS_TRANSFER_COMPLETE,
	EVENT_M_REBOOT,
	EVENT_M_SCHEDULEINFORM,
	EVENT_M_DOWNLOAD,
	__EVENT_MAX
};

struct event {
	struct list_head list;

	int code;
	char *key;
	int method_id;
	mxml_node_t *backup_node;
};

struct event_code
{
	char *code;
	int type;
	int remove_policy;
};

struct scheduled_inform {
	struct uloop_timeout handler_timer ;
	struct list_head list;
	char *key;
};

struct download {
	struct uloop_timeout handler_timer ;
	struct list_head list;
	char *key;
	char *download_url;
	char *file_size;
	char *file_type;
	char *username;
	char *password;
	time_t time_execute;
	mxml_node_t *backup_node;
};

struct notification {

	struct list_head list;

	char *parameter;
	char *value;
	char *type;
};

struct deviceid {
	char *manufacturer;
	char *oui;
	char *product_class;
	char *serial_number;
};

struct cwmp_internal {
	struct list_head events;
	struct list_head notifications;
	struct list_head downloads;
	struct list_head scheduled_informs;
	struct deviceid deviceid;
	int retry_count;
	int download_count;
	int end_session;
	int method_id;
	bool get_rpc_methods;
	bool hold_requests;
	int netlink_sock[2];
};

extern struct cwmp_internal *cwmp;
struct event_code event_code_array[__EVENT_MAX];

static void cwmp_periodic_inform(struct uloop_timeout *timeout);
static void cwmp_do_inform(struct uloop_timeout *timeout);
static void cwmp_do_inform_retry(struct uloop_timeout *timeout);
static inline int rpc_inform(void);
static inline int rpc_get_rpc_methods(void);
static inline int rpc_transfer_complete(mxml_node_t *node, int *method_id);

void cwmp_add_scheduled_inform(char *key, int delay);
void cwmp_add_download(char *key, int delay, char *file_size, char *download_url, char *file_type, char *username, char *password, mxml_node_t *node);
void cwmp_download_launch(struct uloop_timeout *timeout);
void cwmp_init(void);
void cwmp_connection_request(int code);
void cwmp_remove_event(int remove_policy, int method_id);
void cwmp_clear_event_list(void);
void cwmp_add_notification(char *parameter, char *value, char *type, char *notification);
void cwmp_clear_notifications(void);
void cwmp_scheduled_inform(struct uloop_timeout *timeout);
void cwmp_add_handler_end_session(int handler);

int cwmp_inform(void);
int cwmp_handle_messages(void);
int cwmp_set_parameter_write_handler(char *name, char *value);
int cwmp_get_int_event_code(char *code);

struct event *cwmp_add_event(int code, char *key, int method_id, int backup);
long int cwmp_periodic_inform_time(void);
void cwmp_update_value_change(void);
void cwmp_add_inform_timer();
void cwmp_clean(void);
void cwmp_periodic_inform_init(void);
int cwmp_init_deviceid(void);
void cwmp_free_deviceid(void);
#endif

