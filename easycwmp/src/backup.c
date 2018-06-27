/*
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	Copyright (C) 2012-2014 PIVA SOFTWARE (www.pivasoftware.com)
 *		Author: Mohamed Kallel <mohamed.kallel@pivasoftware.com>
 *		Author: Anis Ellouze <anis.ellouze@pivasoftware.com>
 */
#include <unistd.h>
#include <sys/stat.h>
#include <uci.h>
#include "backup.h"
#include "config.h"
#include "xml.h"
#include "cwmp.h"
#include "messages.h"
#include "time.h"

mxml_node_t *backup_tree = NULL;

void str_replace_newline_byspace(char *str)
{
	while(*str)
	{
		if(*str == '\n' || *str == '\r')
			*str = ' ';
		str++;
	}
}

void backup_init(void)
{
#ifdef BACKUP_DATA_IN_CONFIG
	char *val;
	easycwmp_uci_init();
	easycwmp_uci_set_value("easycwmp", "backup", NULL, "backup");
	easycwmp_uci_commit();
	val = easycwmp_uci_get_value("easycwmp", "backup","data");
	if(val[0]=='\0') {
		easycwmp_uci_fini();
		return;
	}
	backup_tree = mxmlLoadString(NULL, val, MXML_OPAQUE_CALLBACK);
	easycwmp_uci_fini();
#else
	FILE *fp;

	if (access(BACKUP_DIR, F_OK) == -1 ) {
		mkdir(BACKUP_DIR, 0777);
	}
	if (access(BACKUP_FILE, F_OK) == -1 ) {
		return;
	}
	fp = fopen(BACKUP_FILE, "r");
	if (fp!=NULL) {
		backup_tree = mxmlLoadFile(NULL, fp, MXML_OPAQUE_CALLBACK);
		fclose(fp);
	}
#endif
	backup_load_download();
	backup_load_event();
	backup_update_all_complete_time_transfer_complete();
}

mxml_node_t *backup_tree_init(void)
{
	mxml_node_t *xml;

	backup_tree = mxmlLoadString(NULL, "<backup_file/>", MXML_OPAQUE_CALLBACK);
	if (!backup_tree) return NULL;
	xml = mxmlNewElement(backup_tree, "cwmp");
	if (!xml) return NULL;
	return xml;
}

int backup_save_file(void) {
#ifdef BACKUP_DATA_IN_CONFIG
	char *val;
	int len;
	if (backup_tree == NULL)
		return 0;
	easycwmp_uci_init();
	val = mxmlSaveAllocString(backup_tree, MXML_NO_CALLBACK);
	len = strlen(val);
	if (len > 0 && val[len - 1] == '\n')
		val[len - 1]= '\0';
	str_replace_newline_byspace(val);
	easycwmp_uci_set_value("easycwmp", "backup", "data", val);
	easycwmp_uci_commit();
	easycwmp_uci_fini();
	free(val);
	return 0;
#else
	FILE *fp;
	char *val;
	int len;

	if (backup_tree == NULL)
		return 0;

	fp = fopen(BACKUP_FILE, "w");
	if (fp!=NULL) {
		val = mxmlSaveAllocString(backup_tree, MXML_NO_CALLBACK);
		len = strlen(val);
		if (len > 0 && val[len - 1] == '\n')
			val[len - 1]= '\0';
		str_replace_newline_byspace(val);
		fprintf(fp, "%s", val);
		fclose(fp);
		free(val);
		return 0;
	}
	return -1;
#endif
}

void backup_add_acsurl(char *acs_url)
{
	mxml_node_t *data, *b;

	cwmp_clean();
	mxmlDelete(backup_tree);
	b = backup_tree_init();
	data = mxmlNewElement(b, "acs_url");
	data = mxmlNewOpaque(data, acs_url);
	backup_save_file();
	cwmp_add_event(EVENT_BOOTSTRAP, NULL, 0, EVENT_BACKUP);
	cwmp_add_inform_timer();
}

void backup_check_acs_url(void)
{
	mxml_node_t *b;

	b = mxmlFindElement(backup_tree, backup_tree, "acs_url", NULL, NULL, MXML_DESCEND);
	if (!b || (b->child && b->child->type == MXML_OPAQUE && b->child->value.opaque &&
		strcmp(config->acs->url, b->child->value.opaque) != 0)) {
		backup_add_acsurl(config->acs->url);
	}
}

mxml_node_t *backup_add_transfer_complete(char *command_key, int fault_code, char *start_time, int method_id)
{
	mxml_node_t  *data, *m, *b;
	char c[16];

	data = mxmlFindElement(backup_tree, backup_tree, "cwmp", NULL, NULL, MXML_DESCEND);
	if (!data) return NULL;

	m = mxmlNewElement(data, "transfer_complete");
	if (!m) return NULL;
	b = mxmlNewElement(m, "command_key");
	if (!b) return NULL;
	b = mxmlNewOpaque(b, command_key);
	if (!b) return NULL;
	b = mxmlNewElement(m, "fault_code");
	if (!b) return NULL;
	b = mxmlNewOpaque(b, fault_array[fault_code].code);
	if (!b) return NULL;
	b = mxmlNewElement(m, "fault_string");
	if (!b) return NULL;
	b = mxmlNewOpaque(b, fault_array[fault_code].string);
	if (!b) return NULL;
	b = mxmlNewElement(m, "start_time");
	if (!b) return NULL;
	b = mxmlNewOpaque(b, start_time);
	if (!b) return NULL;
	b = mxmlNewElement(m, "complete_time");
	if (!b) return NULL;
	b = mxmlNewOpaque(b, UNKNOWN_TIME);
	if (!b) return NULL;
	b = mxmlNewElement(m, "method_id");
	if (!b) return NULL;
	sprintf(c, "%d", method_id);
	b = mxmlNewOpaque(b, c);
	if (!b) return NULL;

	backup_save_file();
	return m;
}

int backup_update_fault_transfer_complete(mxml_node_t *node, int fault_code)
{
	mxml_node_t  *b;

	b = mxmlFindElement(node, node, "fault_code", NULL, NULL, MXML_DESCEND);
	if (!b) return -1;
	if (b->child && b->child->type == MXML_OPAQUE) {
		mxmlDelete(b->child);
	}
	b = mxmlNewOpaque(b, fault_array[fault_code].code);
	if (!b) return -1;

	b = mxmlFindElement(node, node, "fault_string", NULL, NULL, MXML_DESCEND);
	if (!b) return -1;
	if (b->child && b->child->type == MXML_OPAQUE) {
		mxmlDelete(b->child);
	}
	b = mxmlNewOpaque(b, fault_array[fault_code].string);
	if (!b) return -1;

	backup_save_file();
	return 0;
}

int backup_update_complete_time_transfer_complete(mxml_node_t *node)
{
	mxml_node_t  *b;

	b = mxmlFindElement(node, node, "complete_time", NULL, NULL, MXML_DESCEND);
	if (!b) return -1;
	if (b->child && b->child->type == MXML_OPAQUE) {
		mxmlDelete(b->child);
	}
	b = mxmlNewOpaque(b, mix_get_time());
	if (!b) return -1;

	backup_save_file();
	return 0;
}

int backup_update_all_complete_time_transfer_complete(void)
{
	mxml_node_t  *b, *n = backup_tree;
	while (n = mxmlFindElement(n, backup_tree, "transfer_complete", NULL, NULL, MXML_DESCEND)) {
		b = mxmlFindElement(n, n, "complete_time", NULL, NULL, MXML_DESCEND);
		if (!b) return -1;
		if (b->child && b->child->type == MXML_OPAQUE && b->child->value.opaque) {
			if (strcmp(b->child->value.opaque, UNKNOWN_TIME) != 0) continue;
			mxmlDelete(b->child);
			b = mxmlNewOpaque(b, mix_get_time());
			if (!b) return -1;
		}
	}
	backup_save_file();
	return 0;
}

mxml_node_t *backup_check_transfer_complete(void)
{
	mxml_node_t *data;
	data = mxmlFindElement(backup_tree, backup_tree, "transfer_complete", NULL, NULL, MXML_DESCEND);
	return data;
}

int backup_extract_transfer_complete( mxml_node_t *node, char **msg_out, int *method_id)
{
	mxml_node_t *tree_m, *b, *n;
	char *val;

	tree_m = mxmlLoadString(NULL, CWMP_TRANSFER_COMPLETE_MESSAGE, MXML_OPAQUE_CALLBACK);
	if (!tree_m) goto error;

	if(xml_add_cwmpid(tree_m)) goto error;

	b = mxmlFindElement(node, node, "command_key", NULL, NULL, MXML_DESCEND);
	if (!b) goto error;
	n = mxmlFindElement(tree_m, tree_m, "CommandKey", NULL, NULL, MXML_DESCEND);
	if (!n) goto error;
	if (b->child && b->child->type == MXML_OPAQUE && b->child->value.opaque) {
		b = b->child;
		val = xml_get_value_with_whitespace(&b, b->parent);
		n = mxmlNewOpaque(n, val);
		FREE(val);
	}
	else
		n = mxmlNewOpaque(n, "");
	if (!n) goto error;

	b = mxmlFindElement(node, node, "fault_code", NULL, NULL, MXML_DESCEND);
	if (!b) goto error;
	n = mxmlFindElement(tree_m, tree_m, "FaultCode", NULL, NULL, MXML_DESCEND);
	if (!n) goto error;
	n = mxmlNewOpaque(n, b->child->value.opaque);
	if (!n) goto error;

	b = mxmlFindElement(node, node, "fault_string", NULL, NULL, MXML_DESCEND);
	if (!b) goto error;
	if (b->child && b->child->type == MXML_OPAQUE && b->child->value.opaque) {
		n = mxmlFindElement(tree_m, tree_m, "FaultString", NULL, NULL, MXML_DESCEND);
		if (!n) goto error;
		b = b->child;
		char *c = xml_get_value_with_whitespace(&b, b->parent);
		n = mxmlNewOpaque(n, c);
		free(c);
		if (!n) goto error;
	}

	b = mxmlFindElement(node, node, "start_time", NULL, NULL, MXML_DESCEND);
	if (!b) goto error;
	n = mxmlFindElement(tree_m, tree_m, "StartTime", NULL, NULL, MXML_DESCEND);
	if (!n) goto error;
	n = mxmlNewOpaque(n, b->child->value.opaque);
	if (!n) goto error;

	b = mxmlFindElement(node, node, "complete_time", NULL, NULL, MXML_DESCEND);
	if (!b) goto error;
	n = mxmlFindElement(tree_m, tree_m, "CompleteTime", NULL, NULL, MXML_DESCEND);
	if (!n) goto error;
	n = mxmlNewOpaque(n,  b->child->value.opaque);
	if (!n) goto error;

	b = mxmlFindElement(node, node, "method_id", NULL, NULL, MXML_DESCEND);
	if (!b) goto error;
	*method_id = atoi(b->child->value.opaque);

	*msg_out = mxmlSaveAllocString(tree_m, xml_format_cb);
	mxmlDelete(tree_m);
	return 0;
error:
	mxmlDelete(tree_m);
	return -1;
}

int backup_remove_transfer_complete(mxml_node_t *node)
{
	mxmlDelete(node);
	backup_save_file();
	return 0;
}

mxml_node_t *backup_add_download(char *key, int delay, char *file_size, char *download_url, char *file_type, char *username, char *password)
{
	mxml_node_t *tree, *data, *b, *n;
	char time_execute[16];

	if (sprintf(time_execute,"%u",delay + (unsigned int)time(NULL)) < 0) return NULL;

	data = mxmlFindElement(backup_tree, backup_tree, "cwmp", NULL, NULL, MXML_DESCEND);
	if (!data) return NULL;
	b = mxmlNewElement(data, "download");
	if (!b) return NULL;

	n = mxmlNewElement(b, "command_key");
	if (!n) return NULL;
	n = mxmlNewOpaque(n, key);
	if (!n) return NULL;

	n = mxmlNewElement(b, "file_type");
	if (!n) return NULL;
	n = mxmlNewOpaque(n, file_type);
	if (!n) return NULL;

	n = mxmlNewElement(b, "url");
	if (!n) return NULL;
	n = mxmlNewOpaque(n, download_url);
	if (!n) return NULL;

	n = mxmlNewElement(b, "username");
	if (!n) return NULL;
	n = mxmlNewOpaque(n, username);
	if (!n) return NULL;

	n = mxmlNewElement(b, "password");
	if (!n) return NULL;
	n = mxmlNewOpaque(n, password);
	if (!n) return NULL;

	n = mxmlNewElement(b, "file_size");
	if (!n) return NULL;
	n = mxmlNewOpaque(n, file_size);
	if (!n) return NULL;

	n = mxmlNewElement(b, "time_execute");
	if (!n) return NULL;
	n = mxmlNewOpaque(n, time_execute);
	if (!n) return NULL;

	backup_save_file();
	return b;
}

int backup_load_download(void)
{
	int delay = 0;
	unsigned int t;
	mxml_node_t *data, *b, *c;
	char *download_url = NULL, *file_size = NULL,
		*command_key = NULL, *file_type = NULL,
		*username = NULL, *password = NULL, *val = NULL;

	data = mxmlFindElement(backup_tree, backup_tree, "cwmp", NULL, NULL, MXML_DESCEND);
	if (!data) return -1;
	b = data;

	while (b = mxmlFindElement(b, data, "download", NULL, NULL, MXML_DESCEND)) {
		c = mxmlFindElement(b, b, "command_key",NULL, NULL, MXML_DESCEND);
		if (!c) return -1;
		if (c->child && c->child->type == MXML_OPAQUE && c->child->value.opaque) {
			c = c->child;
			val = xml_get_value_with_whitespace(&c, c->parent);
			command_key = val;
		}
		else
			command_key = strdup("");

		c = mxmlFindElement(b, b, "url",NULL, NULL, MXML_DESCEND);
		if (!c) goto error;
		if(c->child)
			download_url = c->child->value.opaque;
		else
			download_url = "";

		c = mxmlFindElement(b, b, "username",NULL, NULL, MXML_DESCEND);
		if (!c) goto error;
		if (c->child && c->child->type == MXML_OPAQUE && c->child->value.opaque) {
			c = c->child;
			val = xml_get_value_with_whitespace(&c, c->parent);
			username = val;
		}
		else
			username = strdup("");

		c = mxmlFindElement(b, b, "password",NULL, NULL, MXML_DESCEND);
		if (!c) goto error;
		if (c->child && c->child->type == MXML_OPAQUE && c->child->value.opaque) {
			c = c->child;
			val = xml_get_value_with_whitespace(&c, c->parent);
			password = val;
		}
		else
			password = strdup("");

		c = mxmlFindElement(b, b, "file_size",NULL, NULL, MXML_DESCEND);
		if (!c) goto error;
		if(c->child)
			file_size = c->child->value.opaque;
		else
			file_size = "";

		c = mxmlFindElement(b, b, "time_execute",NULL, NULL, MXML_DESCEND);
		if (!c) goto error;
		if(c->child) {
			sscanf(c->child->value.opaque, "%u", &t);
			delay = t - time(NULL);
		}

		c = mxmlFindElement(b, b, "file_type",NULL, NULL, MXML_DESCEND);
		if (!c) goto error;
		if (c->child && c->child->type == MXML_OPAQUE && c->child->value.opaque) {
			c = c->child;
			file_type = xml_get_value_with_whitespace(&c, c->parent);
		}
		else
			file_type = strdup("");

		cwmp_add_download(command_key, delay, file_size, download_url, file_type, username, password, b);
		FREE(command_key);
		FREE(username);
		FREE(password);
		FREE(file_type);
	}
	return 0;
error:
	FREE(command_key);
	FREE(username);
	FREE(password);
	FREE(file_type);
	return -1;
}

int backup_remove_download(mxml_node_t *node)
{
	mxmlDelete(node);
	backup_save_file();
	return 0;
}

mxml_node_t *backup_add_event(int code, char *key, int method_id)
{
	mxml_node_t *b = backup_tree, *n, *data;
	char *e = NULL, *c = NULL;

	data = mxmlFindElement(backup_tree, backup_tree, "cwmp", NULL, NULL, MXML_DESCEND);
	if (!data) goto error;
	n = mxmlNewElement(data, "event");
	if (!n) goto error;

	if (asprintf(&e, "%d", code) == -1) goto error;
	b = mxmlNewElement(n, "event_number");
	if (!b) goto error;
	b = mxmlNewOpaque(b, e);
	if (!b) goto error;

	if(key) {
		b = mxmlNewElement(n, "event_key");
		if (!b) goto error;
		b = mxmlNewOpaque(b, key);
		if (!b) goto error;
	}

	if (method_id) {
		if (asprintf(&c, "%d", method_id) == -1) goto error;
		b = mxmlNewElement(n, "event_method_id");
		if (!b) goto error;
		b = mxmlNewOpaque(b, c);
		if (!b) goto error;
	}

	backup_save_file();

out:
	free(e);
	free(c);
	return n;

error:
	free(e);
	free(c);
	return NULL;
}

int backup_load_event(void)
{
	mxml_node_t *data, *b, *c;
	char *event_num = NULL, *key = NULL;
	int method_id = 0;
	struct event *e;

	data = mxmlFindElement(backup_tree, backup_tree, "cwmp", NULL, NULL, MXML_DESCEND);
	if (!data) return -1;
	b = data;
	while (b = mxmlFindElement(b, data, "event", NULL, NULL, MXML_DESCEND)) {
		c = mxmlFindElement(b, b, "event_number",NULL, NULL, MXML_DESCEND);
		if (!c || !c->child || c->child->type != MXML_OPAQUE) return -1;
		event_num = c->child->value.opaque;

		c = mxmlFindElement(b, b, "event_key", NULL, NULL, MXML_DESCEND);
		if (c && c->child && c->child->type == MXML_OPAQUE && c->child->value.opaque) {
			c = c->child;
			key = xml_get_value_with_whitespace(&c, c->parent);
		}
		else
			key = NULL;

		c = mxmlFindElement(b, b, "event_method_id", NULL, NULL, MXML_DESCEND);
		if(c && c->child && c->child->type == MXML_OPAQUE)
			method_id = atoi(c->child->value.opaque);

		if(event_num) {
			if (e = cwmp_add_event(atoi(event_num), key, method_id, EVENT_NO_BACKUP))
				e->backup_node = b;
			cwmp_add_inform_timer();
		}
		FREE(key);
	}
	return 0;
}

int backup_remove_event(mxml_node_t *b)
{
	mxmlDelete(b);
	backup_save_file();
	return 0;
}
