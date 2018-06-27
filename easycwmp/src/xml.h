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

#ifndef _EASYCWMP_XML_H__
#define _EASYCWMP_XML_H__

#include <microxml.h>
#include <libubox/uloop.h>

#define SECDTOMSEC 1000
#define UNKNOWN_TIME "0001-01-01T00:00:00Z"

enum notify {
	FAULT_0,	// no fault
	FAULT_9000, // Method not supported
	FAULT_9001, // Request denied
	FAULT_9002, // Internal error
	FAULT_9003, // Invalid arguments
	FAULT_9004, // Resources exceeded
	FAULT_9005, // Invalid parameter name
	FAULT_9006, // Invalid parameter type
	FAULT_9007, // Invalid parameter value
	FAULT_9008, // Attempt to set a non-writable parameter
	FAULT_9009, // Notification request rejected
	FAULT_9010, // Download failure
	FAULT_9011, // Upload failure
	FAULT_9012, // File transfer server authentication failure
	FAULT_9013, // Unsupported protocol for file transfer
	FAULT_9014, // Download failure: unable to join multicast group
	FAULT_9015, // Download failure: unable to contact file server
	FAULT_9016, // Download failure: unable to access file
	FAULT_9017, // Download failure: unable to complete download
	FAULT_9018, // Download failure: file corrupted
	FAULT_9019, // Download failure: file authentication failure
	__FAULT_MAX
};

struct fault_code
{
	char *code;
	char *type;
	char *string;
};

struct cwmp_namespaces
{
	char *soap_env[8]; //Some ACS soap messages contains more than 1 env
	char *soap_enc;
	char *xsd;
	char *xsi;
	char *cwmp;
};

struct rpc_method {
	const char *name;
	int (*handler)(mxml_node_t *body_in, mxml_node_t *tree_in,
			mxml_node_t *tree_out);
};

extern struct fault_code fault_array[__FAULT_MAX];

void xml_exit(void);

int xml_prepare_inform_message(char **msg_out);
int xml_parse_inform_response_message(char *msg_in);
int xml_prepare_get_rpc_methods_message(char **msg_out);
int xml_parse_get_rpc_methods_response_message(char *msg_in);
int xml_handle_message(char *msg_in, char **msg_out);
int xml_get_index_fault(char *fault_code);

static int xml_handle_get_rpc_methods(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_set_parameter_values(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_get_parameter_values(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_get_parameter_names(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_set_parameter_attributes(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_download(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_factory_reset(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_reboot(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_get_parameter_attributes(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_schedule_inform(mxml_node_t *node,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_AddObject(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static int xml_handle_DeleteObject(mxml_node_t *body_in,
					mxml_node_t *tree_in,
					mxml_node_t *tree_out);

static void xml_do_inform(struct uloop_timeout *timeout);
const char *xml_format_cb(mxml_node_t *node, int pos);
char *xml_get_value_with_whitespace(mxml_node_t **b, mxml_node_t *body_in);
mxml_node_t *xml_create_generic_fault_message(mxml_node_t *body, int code);
int xml_add_cwmpid(mxml_node_t *tree);
int xml_parse_transfer_complete_response_message(char *msg_in);
int xml_create_set_parameter_value_fault_message(mxml_node_t *body, int code);
#endif

