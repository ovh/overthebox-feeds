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

#ifndef _EASYCWMP_JSON_H__
#define _EASYCWMP_JSON_H__

#ifdef JSONC
 #include <json-c/json.h>
#else
 #include <json/json.h>
#endif

int json_handle_get_parameter_value(char *line);
int json_handle_get_parameter_name(char *line);
int json_handle_get_parameter_attribute(char *line);
int json_handle_method_status(char *line);
int json_handle_set_parameter(char *line);
int json_handle_deviceid(char *line);
int json_handle_add_object(char *line);
int json_handle_check_parameter_value_change(char *line);

#endif
