/*
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 2 of the License, or
 *	(at your option) any later version.
 *	HTTP digest auth functions: originally imported from libmicrohttpd
 *
 *	Copyright (C) 2012-2014 PIVA SOFTWARE (www.pivasoftware.com)
 *		Author: Emna Trigui <emna.trigui@pivasoftware.com>
 */

#ifndef BASICAUTH_H_
#define BASICAUTH_H_

#define REALM "realm@easycwmp"

#define MHD_YES 1

#define MHD_NO 0

int http_basic_auth_fail_response(FILE *fp, const char *realm);
int http_basic_auth_check(char buffer[BUFSIZ], char *username, char *password);

#endif /* BASICAUTH_H_ */
