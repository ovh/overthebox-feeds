/*
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	Copyright (C) 2012-2015 PIVA SOFTWARE (www.pivasoftware.com)
 *		Author: Mohamed Kallel <mohamed.kallel@pivasoftware.com>
 *		Author: Anis Ellouze <anis.ellouze@pivasoftware.com>
 *	Copyright (C) 2011-2012 Luka Perkov <freecwmp@lukaperkov.net>
 */

#include <stdlib.h>
#include <string.h>
#include <libubox/uloop.h>

#include "json.h"
#include "cwmp.h"
#include "config.h"
#include "external.h"
#include "easycwmp.h"
#include "http.h"
#include "xml.h"
#include "backup.h"
#include "time.h" 
#include "log.h"

struct event_code event_code_array[] = {
	[EVENT_BOOTSTRAP] = {"0 BOOTSTRAP", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_BOOT] = {"1 BOOT", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_PERIODIC] = {"2 PERIODIC", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_SCHEDULED] = {"3 SCHEDULED", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_VALUE_CHANGE] = {"4 VALUE CHANGE", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_KICKED] = {"5 KICKED", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_CONNECTION_REQUEST] = {"6 CONNECTION REQUEST", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM|EVENT_REMOVE_NO_RETRY},
	[EVENT_TRANSFER_COMPLETE] = {"7 TRANSFER COMPLETE", EVENT_SINGLE, EVENT_REMOVE_AFTER_TRANSFER_COMPLETE},
	[EVENT_DIAGNOSTICS_COMPLETE] = {"8 DIAGNOSTICS COMPLETE", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_REQUEST_DOWNLOAD] = {"9 REQUEST DOWNLOAD", EVENT_SINGLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_AUTONOMOUS_TRANSFER_COMPLETE] = {"10 AUTONOMOUS TRANSFER COMPLETE", EVENT_SINGLE, EVENT_REMOVE_AFTER_TRANSFER_COMPLETE},
	[EVENT_M_REBOOT] = {"M Reboot", EVENT_MULTIPLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_M_SCHEDULEINFORM] = {"M ScheduleInform", EVENT_MULTIPLE, EVENT_REMOVE_AFTER_INFORM},
	[EVENT_M_DOWNLOAD] = {"M Download", EVENT_MULTIPLE, EVENT_REMOVE_AFTER_TRANSFER_COMPLETE}
};

struct cwmp_internal *cwmp;

static struct uloop_timeout inform_timer = { .cb = cwmp_do_inform };
static struct uloop_timeout periodic_inform_timer = { .cb = cwmp_periodic_inform };
static struct uloop_timeout inform_timer_retry = { .cb = cwmp_do_inform };

void cwmp_add_inform_timer()
{
	uloop_timeout_set(&inform_timer, 10);
}

static void cwmp_periodic_inform(struct uloop_timeout *timeout)
{
	if (config->acs->periodic_enable && config->acs->periodic_interval) {
		uloop_timeout_set(&periodic_inform_timer, config->acs->periodic_interval * SECDTOMSEC);
	}
	if (config->acs->periodic_enable) {
		cwmp_add_event(EVENT_PERIODIC, NULL, 0, EVENT_BACKUP);
		cwmp_add_inform_timer();
	}
}

void cwmp_periodic_inform_init(void)
{
	uloop_timeout_cancel(&periodic_inform_timer);
	if (config->acs->periodic_enable && config->acs->periodic_interval) {
		if (config->acs->periodic_time != -1){
			log_message(NAME, L_NOTICE, "init periodic inform: reference time = %ld, interval = %d\n", config->acs->periodic_time, config->acs->periodic_interval);
			uloop_timeout_set(&periodic_inform_timer, cwmp_periodic_inform_time() * SECDTOMSEC);
		}
		else {
			log_message(NAME, L_NOTICE, "init periodic inform: reference time = n/a, interval = %d\n", config->acs->periodic_interval);
			uloop_timeout_set(&periodic_inform_timer, config->acs->periodic_interval * SECDTOMSEC);
		}
	}
}

static void cwmp_do_inform(struct uloop_timeout *timeout)
{
	uloop_timeout_cancel(&inform_timer_retry);
	cwmp_inform();
}

static inline int cwmp_retry_count_interval(int retry_count)
{
	switch (retry_count) {
		case 0 : return 0;
		case 1 : return 7;
		case 2 : return 15;
		case 3 : return 30;
		case 4 : return 60;
		case 5 : return 120;
		case 6 : return 240;
		case 7 : return 480;
		case 8 : return 960;
		case 9 : return 1920;
		default : return 3840;
	}
}

static inline void cwmp_retry_session() {
	struct event *n, *p;
	int rp, retry = 1;

	list_for_each_entry_safe(n, p, &cwmp->events, list) {
		rp = event_code_array[n->code].remove_policy;
		if ((rp & EVENT_REMOVE_NO_RETRY)) {
			retry = 0;
		} else {
			retry = 1;
			break;
		}
	}
	cwmp_remove_event(EVENT_REMOVE_NO_RETRY, 0);
	if (retry == 0 && cwmp->retry_count == 0)
		return;
	cwmp->retry_count++;
	int rtime = cwmp_retry_count_interval(cwmp->retry_count);
	log_message(NAME, L_NOTICE, "retry session in %d sec, RetryCount = %d\n", rtime, cwmp->retry_count);
	uloop_timeout_set(&inform_timer_retry, SECDTOMSEC * rtime);
}

static inline int rpc_transfer_complete(mxml_node_t *node, int *method_id)
{
	char *msg_in = NULL, *msg_out = NULL;
	int error = 0, count = 0;

	if ( backup_extract_transfer_complete(node, &msg_out, method_id)) {
		D(" Transfer Complete xml message creating failed\n");
		return -1;
	}

	log_message(NAME, L_NOTICE, "send RPC ACS TransferComplete\n");

	do {
		FREE(msg_in);

		if (http_send_message(msg_out, &msg_in)) {
			D("sending Transfer Complete http message failed\n");
			error = -1; break;
		}
		if (!msg_in)
			break;

		error = xml_parse_transfer_complete_response_message(msg_in);
		if (error == -1) {
			D("parse Transfer Complete xml message from ACS failed\n");
			break;
		}
		else if (error && (error != FAULT_ACS_8005)) {
			error = 0; break;
		}
	} while(error && (count++)<10);

	FREE(msg_out);
	FREE(msg_in);
	return error;
}

static inline int rpc_get_rpc_methods()
{
	char *msg_in = NULL, *msg_out = NULL;
	int error = 0, count = 0;

	if (xml_prepare_get_rpc_methods_message(&msg_out)) {
		D("GetRPCMethods xml message creating failed\n");
		return -1;
	}

	log_message(NAME, L_NOTICE, "send RPC ACS GetRPCMethods\n");

	do {
		FREE(msg_in);

		if (http_send_message(msg_out, &msg_in)) {
			D("sending GetRPCMethods http message failed\n");
			error = -1; break;
		}

		if (!msg_in)
			break;

		error = xml_parse_get_rpc_methods_response_message(msg_in);
		if (error == -1) {
			D("parse GetRPCMethods xml message from ACS failed\n");
			break;
		}
		else if (error && (error != FAULT_ACS_8005)) {
			error = 0; break;
		}
	} while(error && (count++)<10);

	FREE(msg_out);
	FREE(msg_in);
	return error;
}

static inline int rpc_inform()
{
	char *msg_in = NULL, *msg_out = NULL;
	int error = 0, count = 0;

	if (xml_prepare_inform_message(&msg_out)) {
		D("Inform xml message creating failed\n");
		return -1;
	}

	log_message(NAME, L_NOTICE, "send Inform\n");

	do {
		FREE(msg_in);

		if (http_send_message(msg_out, &msg_in)) {
			D("sending Inform http message failed\n");
			error = -1; break;
		}

		if (!msg_in) {
			D("parse Inform xml message from ACS: Empty message\n");
			error = -1; break;
		}

		error = xml_parse_inform_response_message(msg_in);
		if (error && (error != FAULT_ACS_8005)) {
			D("parse Inform xml message from ACS failed\n");
			error = -1; break;
		}
	} while(error && (count++)<10);

	FREE(msg_out);
	FREE(msg_in);
	return error;
}

void cwmp_add_handler_end_session(int handler)
{
	cwmp->end_session |= handler;
}

static void cwmp_handle_end_session(void)
{
	external_action_simple_execute("apply", "service", NULL);
	external_action_handle(NULL);
	if (cwmp->end_session & ENDS_FACTORY_RESET) {
		log_message(NAME, L_NOTICE, "end session: factory reset\n");
		external_action_simple_execute("factory_reset", NULL, NULL);
		external_action_handle(NULL);
		exit(EXIT_SUCCESS);
	}
	if (cwmp->end_session & ENDS_REBOOT) {
		log_message(NAME, L_NOTICE, "end session: reboot\n");
		external_action_simple_execute("reboot", NULL, NULL);
		external_action_handle(NULL);
		exit(EXIT_SUCCESS);
	}
	if (cwmp->end_session & ENDS_RELOAD_CONFIG) {
		log_message(NAME, L_NOTICE, "end session: configuration reload\n");
		config_load();
	}
	cwmp->end_session = 0;
}

int cwmp_inform(void)
{
	mxml_node_t *node;
	int method_id;

	log_message(NAME, L_NOTICE, "start session\n");
	if (http_client_init()) {
		D("initializing http client failed\n");
		goto error;
	}
	if (external_init()) {
		D("external scripts initialization failed\n");
		goto error;
	}

	if(rpc_inform()) {
		log_message(NAME, L_NOTICE, "sending Inform failed\n");
		goto error;
	}
	log_message(NAME, L_NOTICE, "receive InformResponse from the ACS\n");

	cwmp_remove_event(EVENT_REMOVE_AFTER_INFORM, 0);
	cwmp_clear_notifications();

	do {
		while((node = backup_check_transfer_complete()) && !cwmp->hold_requests) {
			if(rpc_transfer_complete(node, &method_id)) {
				log_message(NAME, L_NOTICE, "sending TransferComplete failed\n");
				goto error;
			}
			log_message(NAME, L_NOTICE, "receive TransferCompleteResponse from the ACS\n");

			backup_remove_transfer_complete(node);
			cwmp_remove_event(EVENT_REMOVE_AFTER_TRANSFER_COMPLETE, method_id);
			if (!backup_check_transfer_complete())
				cwmp_remove_event(EVENT_REMOVE_AFTER_TRANSFER_COMPLETE, 0);
		}
		if(cwmp->get_rpc_methods && !cwmp->hold_requests) {
			if(rpc_get_rpc_methods()) {
				log_message(NAME, L_NOTICE, "sending GetRPCMethods failed\n");
				goto error;
			}
			log_message(NAME, L_NOTICE, "receive GetRPCMethodsResponse from the ACS\n");

			cwmp->get_rpc_methods = false;
		}

		if (cwmp_handle_messages()) {
			D("handling xml message failed\n");
			goto error;
		}
		cwmp->hold_requests = false;
	} while (cwmp->get_rpc_methods || backup_check_transfer_complete());
	
	http_client_exit();
	xml_exit();
	cwmp_handle_end_session();
	external_exit();
	cwmp->retry_count = 0;
	log_message(NAME, L_NOTICE, "end session success\n");
	return 0;

error:
	http_client_exit();
	xml_exit();
	cwmp_handle_end_session();
	external_exit();
	log_message(NAME, L_NOTICE, "end session failed\n");
	cwmp_retry_session();

	return -1;
}

int cwmp_handle_messages(void)
{
	char *msg_in, *msg_out;
	msg_in = msg_out = NULL;

	log_message(NAME, L_NOTICE, "send empty message to the ACS\n");

	while (1) {
		FREE(msg_in);

		if (http_send_message(msg_out, &msg_in)) {
			D("sending http message failed\n");
			goto error;
		}

		if (!msg_in) {
			log_message(NAME, L_NOTICE, "receive empty message from the ACS\n");
			break;
		}

		FREE(msg_out);

		if (xml_handle_message(msg_in, &msg_out)) {
			log_message(NAME, L_NOTICE, "handling message failed\n");
			D("xml handling message failed\n");
			goto error;
		}

		if (!msg_out) {
			log_message(NAME, L_NOTICE, "handling message failed\n");
			D("acs response message is empty\n");
			goto error;
		}
	}
	FREE(msg_in);
	FREE(msg_out);

	return 0;

error:
	FREE(msg_in);
	FREE(msg_out);
	return -1;
}

void cwmp_connection_request(int code)
{
	cwmp_add_event(code, NULL, 0, EVENT_NO_BACKUP);
	cwmp_add_inform_timer();
}

void cwmp_scheduled_inform(struct uloop_timeout *timeout)
{
	struct scheduled_inform *s;

	s = container_of(timeout, struct scheduled_inform, handler_timer);

	cwmp_add_event(EVENT_SCHEDULED, NULL, 0, EVENT_BACKUP);
	cwmp_add_event(EVENT_M_SCHEDULEINFORM, s->key, 0, EVENT_BACKUP);
	cwmp_add_inform_timer();
	list_del(&s->list);
	FREE(s->key);
	FREE(s);
}

void cwmp_add_scheduled_inform(char *key, int delay)
{
	struct scheduled_inform *s = NULL;

	s = calloc(1, sizeof(*s));
	if (!s) return;
	log_message(NAME, L_NOTICE, "scheduled inform in %d sec\n", delay);
	s->key = key ? strdup(key) : NULL;
	s->handler_timer.cb = cwmp_scheduled_inform;
	list_add_tail(&s->list, &cwmp->scheduled_informs);
	uloop_timeout_set(&s->handler_timer, SECDTOMSEC * delay);
}

static inline void cwmp_free_download(struct download *d)
{
	free(d->download_url);
	free(d->file_size);
	free(d->file_type);
	free(d->key);
	free(d->password);
	free(d->username);
	free(d);
}

void cwmp_download_launch(struct uloop_timeout *timeout)
{
	struct download *d;
	char *start_time = NULL, *status = NULL, *fault = NULL;
	mxml_node_t *node;
	int code = FAULT_0;

	d = container_of(timeout, struct download, handler_timer);

	log_message(NAME, L_NOTICE, "start download url = %s, FileType = '%s', CommandKey = '%s'\n",
			d->download_url, d->file_type, d->key);

	if (external_init()) {
		D("external scripts initialization failed\n");
		return;
	}

	start_time = mix_get_time();
	external_action_download_execute(d->download_url, d->file_type, d->file_size, d->username, d->password);
	external_action_handle(json_handle_method_status);
	backup_remove_download(d->backup_node);
	list_del(&d->list);
	cwmp->download_count--;
	node = backup_add_transfer_complete(d->key, code, start_time, ++cwmp->method_id);
	if(!node) {
		external_exit();
		cwmp_free_download(d);
		return;
	}
	cwmp_add_event(EVENT_TRANSFER_COMPLETE, NULL, 0, EVENT_BACKUP);
	cwmp_add_event(EVENT_M_DOWNLOAD, d->key, cwmp->method_id, EVENT_BACKUP);

	external_fetch_method_resp_status(&status, &fault);
	if (fault && fault[0]=='9') {
		code = xml_get_index_fault(fault);
		goto end_fault ;
	}
	if(!status || status[0] == '\0') {
		code = FAULT_9002;
		goto end_fault;
	}
	FREE(status);
	FREE(fault);
	external_action_simple_execute("apply", "download", d->file_type);
	external_action_handle(json_handle_method_status);
	external_fetch_method_resp_status(&status, &fault);

	if (fault && fault[0]=='9') {
		code = xml_get_index_fault(fault);
		goto end_fault;
	}
	if (!status || status[0] == '\0') {
		code = FAULT_9002;
		goto end_fault;
	}
	if (status[0] == '1') exit(EXIT_SUCCESS);
	goto out;

end_fault :
	log_message(NAME, L_NOTICE, "download error: '%s'\n", fault_array[code].string);
	backup_update_fault_transfer_complete(node, code);

out:
	backup_update_complete_time_transfer_complete(node);
	cwmp_add_inform_timer();
	external_exit();
	cwmp_free_download(d);
	free(status);
	free(fault);
}

void cwmp_add_download(char *key, int delay, char *file_size, char *download_url, char *file_type, char *username, char *password, mxml_node_t *node)
{
	struct download *d = NULL;

	cwmp->download_count++;
	d = calloc(1, sizeof(*d));
	if (!d) return;

	d->key = key ? strdup(key) : NULL;
	d->file_size = file_size ? strdup(file_size) : NULL;
	d->download_url = download_url ? strdup(download_url) : NULL;
	d->file_type = file_type ? strdup(file_type) : NULL;
	d->username = username ? strdup(username) : NULL;
	d->password = password ? strdup(password) : NULL;
	d->handler_timer.cb = cwmp_download_launch;
	d->backup_node = node;
	d->time_execute = time(NULL) + delay;
	list_add_tail(&d->list, &cwmp->downloads);
	log_message(NAME, L_NOTICE, "add download: delay = %d sec, url = %s, FileType = '%s', CommandKey = '%s'\n",
			delay, d->download_url, d->file_type, d->key);

	uloop_timeout_set(&d->handler_timer, SECDTOMSEC * delay);
}

struct event *cwmp_add_event(int code, char *key, int method_id, int backup)
{
	struct event *e = NULL;
	struct list_head *p;

	int type = event_code_array[code].type;

	log_message(NAME, L_NOTICE, "add event '%s'\n", event_code_array[code].code);

	if (type == EVENT_SINGLE) {
		list_for_each(p, &cwmp->events) {
			e = list_entry(p, struct event, list);
			if (e->code == code) {
				return NULL;
			}
		}
	}

	e = calloc(1, sizeof(*e));
	if (!e) return NULL;

	list_add_tail(&e->list, &cwmp->events);
	e->code = code;
	e->key = key ? strdup(key) : NULL;
	e->method_id = method_id;
	if (backup == EVENT_BACKUP)
		e->backup_node = backup_add_event(code, key, method_id);
	return e;
}

void cwmp_remove_event(int remove_policy, int method_id)
{
	struct event *n, *p;
	int rp;

	list_for_each_entry_safe(n, p, &cwmp->events, list) {
		rp = event_code_array[n->code].remove_policy;
		if ((rp & remove_policy) &&
			n->method_id == method_id) {
			list_del(&n->list);
			FREE(n->key);
			backup_remove_event(n->backup_node);
			FREE(n);
		}
	}
}

void cwmp_clear_event_list(void)
{
	struct event *n, *p;

	list_for_each_entry_safe(n, p, &cwmp->events, list) {
		FREE(n->key);
		list_del(&n->list);
		FREE(n);
	}
}

void cwmp_add_notification(char *parameter, char *value, char *type, char *notification)
{
	struct notification *n = NULL;
	struct list_head *p;
	bool uniq = true;

	if (notification[0] == '0')  return;

	list_for_each(p, &cwmp->notifications) {
		n = list_entry(p, struct notification, list);
		if (!strcmp(n->parameter, parameter)) {
			free(n->value);
			n->value = strdup(value);
			uniq = false;
			break;
		}
	}

	if (uniq) {
		n = calloc(1, sizeof(*n));
		if (!n) return;
		list_add_tail(&n->list, &cwmp->notifications);
		n->parameter = strdup(parameter);
		n->value = strdup(value);
		n->type = type ? strdup(type) : strdup("xsd:string");
	}
	cwmp_add_event(EVENT_VALUE_CHANGE, NULL, 0, EVENT_NO_BACKUP);
	if (notification[0] == '2') {
		cwmp_add_inform_timer();
	}
}

void cwmp_clear_notifications(void)
{
	struct notification *n, *p;

	list_for_each_entry_safe(n, p, &cwmp->notifications, list) {
		FREE(n->parameter);
		FREE(n->value);
		FREE(n->type);
		list_del(&n->list);
		FREE(n);
	}
}

void cwmp_free_deviceid(void)
{
	FREE(cwmp->deviceid.manufacturer);
	FREE(cwmp->deviceid.oui);
	FREE(cwmp->deviceid.product_class);
	FREE(cwmp->deviceid.serial_number);
}

int cwmp_init_deviceid(void)
{
	external_action_simple_execute("inform", "device_id", NULL);
	if (external_action_handle(json_handle_deviceid))
		return -1;

	if (!cwmp->deviceid.product_class || cwmp->deviceid.product_class[0] == '\0') {
		D("in device you must define product_class\n");
		return -1;
	}

	if (!cwmp->deviceid.serial_number || cwmp->deviceid.serial_number[0] == '\0') {
		D("in device you must define serial_number\n");
		return -1;
	}

	if (!cwmp->deviceid.manufacturer || cwmp->deviceid.manufacturer[0] == '\0') {
		D("in device you must define manufacturer\n");
		return -1;
	}

	if (!cwmp->deviceid.oui || cwmp->deviceid.oui[0] == '\0') {
		D("in device you must define manufacturer oui\n");
		return -1;
	}

	return 0;
}

void cwmp_update_value_change(void) {
	external_action_simple_execute("update_value_change", NULL, NULL);
	external_action_handle(NULL);
}

void cwmp_clean(void)
{
	struct download *d;
	struct scheduled_inform *s;
	cwmp_clear_event_list();
	cwmp_clear_notifications();
	while (cwmp->downloads.next != &cwmp->downloads){
		d = list_entry(cwmp->downloads.next, struct download, list);
		list_del(&d->list);
		uloop_timeout_cancel(&d->handler_timer);
		cwmp_free_download(d);
	}
	while (cwmp->scheduled_informs.next != &cwmp->scheduled_informs){
		s = list_entry(cwmp->scheduled_informs.next, struct scheduled_inform, list);
		list_del(&s->list);
		uloop_timeout_cancel(&s->handler_timer);
		free(s->key);
		free(s);
	}
	cwmp->download_count = 0;
	cwmp->end_session = 0;
	cwmp->retry_count = 0;
	cwmp->hold_requests = false;
	cwmp->get_rpc_methods = false;
}

int cwmp_get_int_event_code(char *code)
{
	if (!strcasecmp("boot", code) ||
		!strcasecmp("1 boot", code))
		return EVENT_BOOT;

	if (!strcasecmp("periodic", code) ||
		!strcasecmp("2 periodic", code))
		return EVENT_PERIODIC;

	if (!strcasecmp("scheduled", code) ||
		!strcasecmp("3 scheduled", code))
		return EVENT_SCHEDULED;

	if (!strcasecmp("value change", code) ||
		!strcasecmp("value_change", code) ||
		!strcasecmp("4 value change", code))
		return EVENT_VALUE_CHANGE;

	if (!strcasecmp("connection request", code) ||
		!strcasecmp("connection_request", code) ||
		!strcasecmp("6 connection request", code))
		return EVENT_CONNECTION_REQUEST;

	if (!strcasecmp("diagnostics complete", code) ||
		!strcasecmp("diagnostics_complete", code) ||
		!strcasecmp("8 diagnostics complete", code))
		return EVENT_DIAGNOSTICS_COMPLETE;

	return EVENT_BOOTSTRAP;
}

long int cwmp_periodic_inform_time(void)
{
	long int delta_time;
	long int periodic_time;

	delta_time = time(NULL) - config->acs->periodic_time;
	if(delta_time > 0)
		periodic_time = config->acs->periodic_interval - (delta_time % config->acs->periodic_interval);
	else
		periodic_time = (-delta_time) % config->acs->periodic_interval;

	return  periodic_time;
}
