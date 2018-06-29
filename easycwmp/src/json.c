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

#include <stdio.h>


#include "json.h"
#include "cwmp.h"
#include "easycwmp.h"
#include "external.h"

char *json_common_get_string(json_object *js_obj, char *key )
{
	json_object *js_tmp = NULL;
	char *str = NULL;

	js_tmp = json_object_object_get(js_obj, key);

	if (js_tmp == NULL) return NULL;

	str = (char *) json_object_get_string(js_tmp);
	return str;
}

int json_handle_method_status(char *line)
{
	json_object *js_obj;
	char *status, *cfg_load, *fault_code;

	js_obj = json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
		return -1;

	if (status = json_common_get_string(js_obj, "status")) {
		cfg_load = json_common_get_string(js_obj, "config_load");
		if (cfg_load && atoi(cfg_load))
			cwmp->end_session |= ENDS_RELOAD_CONFIG;
	}
	fault_code = json_common_get_string(js_obj, "fault_code");
	external_method_resp_status(status, fault_code);

	json_object_put(js_obj);
	return 0;
}

int json_handle_set_parameter(char *line)
{
	json_object *js_obj;
	char *param_name, *fault_code, *status, *cfg_load;


	js_obj = json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
		return -1;

	if (status = json_common_get_string(js_obj, "status")) {
		cfg_load = json_common_get_string(js_obj, "config_load");
		if (cfg_load && atoi(cfg_load))
			cwmp->end_session |= ENDS_RELOAD_CONFIG;
		external_set_param_resp_status(status);
	}
	else {
		param_name = json_common_get_string(js_obj, "parameter");
		fault_code = json_common_get_string(js_obj, "fault_code");
		external_add_list_paramameter(param_name, NULL, NULL, fault_code);
	}
	json_object_put(js_obj);
	return 0;
}

int json_handle_get_parameter_attribute(char *line)
{
	json_object *js_obj;
	char *param_name, *param_notification, *fault_code;

	js_obj=json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
		return -1;

	param_name = json_common_get_string(js_obj, "parameter");
	param_notification = json_common_get_string(js_obj, "notification");
	fault_code = json_common_get_string(js_obj, "fault_code");

	external_add_list_paramameter(param_name, param_notification, NULL, fault_code);

	json_object_put(js_obj);
	return 0;
}

int json_handle_get_parameter_value(char *line)
{
	json_object *js_obj;
	char *param_name, *param_value, *param_type, *fault_code;

	js_obj=json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
		return -1;

	param_name = json_common_get_string(js_obj, "parameter");
	param_value = json_common_get_string(js_obj, "value");
	param_type = json_common_get_string(js_obj, "type");
	if (param_type == NULL || param_type[0] == '\0')
		param_type = "xsd:string";
	fault_code = json_common_get_string(js_obj, "fault_code");

	external_add_list_paramameter(param_name, param_value, param_type, fault_code);

	json_object_put(js_obj);
	return 0;
}

int json_handle_get_parameter_name(char *line)
{
	json_object *js_obj;
	char *param_name, *param_permission, *fault_code;

	js_obj=json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
			return -1;

	param_name = json_common_get_string(js_obj, "parameter");
	param_permission = json_common_get_string(js_obj, "writable");
	fault_code = json_common_get_string(js_obj, "fault_code");

	external_add_list_paramameter(param_name, param_permission, NULL, fault_code);

	json_object_put(js_obj);
	return 0;
}

int json_handle_deviceid(char *line)
{
	json_object *js_obj;
	char *param_name, *param_permission, *fault_code, *c;

	js_obj=json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
			return -1;

	cwmp_free_deviceid();

	c= json_common_get_string(js_obj, "product_class");
	cwmp->deviceid.product_class = c ? strdup(c) : c;
	c= json_common_get_string(js_obj, "serial_number");
	cwmp->deviceid.serial_number = c ? strdup(c) : c;
	c = json_common_get_string(js_obj, "manufacturer");
	cwmp->deviceid.manufacturer = c ? strdup(c) : c;
	c = json_common_get_string(js_obj, "oui");
	cwmp->deviceid.oui = c ? strdup(c) : c;

	json_object_put(js_obj);
	return 0;
}

int json_handle_add_object(char *line)
{
	json_object *js_obj;
	char *status, *fault_code, *instance;

	js_obj=json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
		return -1;

	status = json_common_get_string(js_obj, "status");
	instance = json_common_get_string(js_obj, "instance");
	fault_code = json_common_get_string(js_obj, "fault_code");

	external_add_obj_resp(status, instance, fault_code);

	json_object_put(js_obj);
	return 0;
}

int json_handle_check_parameter_value_change(char *line)
{
	json_object *js_obj;
	char *param_name, *param_value, *param_notif, *param_type;

	js_obj=json_tokener_parse(line);
	if (js_obj == NULL || json_object_get_type(js_obj) != json_type_object)
		return -1;

	param_name = json_common_get_string(js_obj, "parameter");
	param_value = json_common_get_string(js_obj, "value");
	param_notif = json_common_get_string(js_obj, "notification");
	param_type = json_common_get_string(js_obj, "type");
	if (param_type == NULL || param_type[0] == '\0')
		param_type = "xsd:string";

	cwmp_add_notification(param_name, param_value, param_type, param_notif);

	json_object_put(js_obj);
	return 0;
}
