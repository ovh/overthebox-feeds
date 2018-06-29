/*
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 2 of the License, or
 *	(at your option) any later version.
 *	HTTP digest auth functions: originally imported from libmicrohttpd
 *
 *	Copyright (C) 2012-2014 PIVA SOFTWARE (www.pivasoftware.com)
 *		Author: Oussama Ghorbel <oussama.ghorbel@pivasoftware.com>
 *
 */


#ifndef DIGESTAUTH_H_
#define DIGESTAUTH_H_

#define REALM "realm@easycwmp"
#define OPAQUE "328458fab28345ae87ab3210a8513b14eff452a2"

/**
 * MHD-internal return code for "YES".
 */
#define MHD_YES 1

/**
 * MHD-internal return code for "NO".
 */
#define MHD_NO 0

/**
 * MHD digest auth internal code for an invalid nonce.
 */
#define MHD_INVALID_NONCE -1

int http_digest_auth_fail_response(FILE *fp, const char *http_method,
		const char *url, const char *realm, const char *opaque);

int http_digest_auth_check(const char *http_method, const char *url,
		const char *header, const char *realm, const char *username,
		const char *password, unsigned int nonce_timeout);
void http_digest_init_nonce_priv_key(void);

#endif /* DIGESTAUTH_H_ */
