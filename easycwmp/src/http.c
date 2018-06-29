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
#include <unistd.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <libubox/uloop.h>
#include <libubox/usock.h>
#include <curl/curl.h>

#include "http.h"
#include "config.h"
#include "cwmp.h"
#include "easycwmp.h"
#include "basicauth.h"
#include "digestauth.h"
#include "log.h"

static struct http_client http_c;
static struct http_server http_s;
CURL *curl;
char *http_redirect_url = NULL;

int
http_client_init(void)
{
	if (http_redirect_url) {
		if ((http_c.url = strdup(http_redirect_url)) == NULL)
			return -1;
	}
	else {
		if ((http_c.url = strdup(config->acs->url)) == NULL)
			return -1;
	}

	DDF("+++ HTTP CLIENT CONFIGURATION +++\n");
	DD("url: %s\n", http_c.url);
	if (config->acs->ssl_cert)
		DD("ssl_cert: %s\n", config->acs->ssl_cert);
	if (config->acs->ssl_cacert)
		DD("ssl_cacert: %s\n", config->acs->ssl_cacert);
	if (!config->acs->ssl_verify)
		DD("ssl_verify: SSL certificate validation disabled.\n");
	DDF("--- HTTP CLIENT CONFIGURATION ---\n");

	curl = curl_easy_init();
	if (!curl) return -1;
	curl_easy_setopt(curl, CURLOPT_URL, http_c.url);
	curl_easy_setopt(curl, CURLOPT_USERNAME, config->acs->username ? config->acs->username : "");
	curl_easy_setopt(curl, CURLOPT_PASSWORD, config->acs->password ? config->acs->password : "");
	curl_easy_setopt(curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC|CURLAUTH_DIGEST);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, http_get_response);
	curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30);
# ifdef DEVEL
	curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);
# endif /* DEVEL */
	curl_easy_setopt(curl, CURLOPT_COOKIEFILE, fc_cookies);
	curl_easy_setopt(curl, CURLOPT_COOKIEJAR, fc_cookies);
	if (config->acs->ssl_cert)
		curl_easy_setopt(curl, CURLOPT_SSLCERT, config->acs->ssl_cert);
	if (config->acs->ssl_cacert)
		curl_easy_setopt(curl, CURLOPT_CAINFO, config->acs->ssl_cacert);
	if (!config->acs->ssl_verify)
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);

	log_message(NAME, L_NOTICE, "configured acs url %s\n", http_c.url);
	return 0;
}

void
http_client_exit(void)
{
	FREE(http_c.url);

	if(curl) {
	curl_easy_cleanup(curl);
		curl = NULL;
	}
	curl_global_cleanup();
	if (access(fc_cookies, W_OK) == 0)
		remove(fc_cookies);
}

static size_t
http_get_response(char *buffer, size_t size, size_t rxed, char **msg_in)
{
	char *c;

	if (asprintf(&c, "%s%.*s", *msg_in, size * rxed, buffer) == -1) {
		FREE(*msg_in);
		return -1;
	}

	free(*msg_in);
	*msg_in = c;

	return size * rxed;
}

int8_t
http_send_message(char *msg_out, char **msg_in)
{
	CURLcode res;
	char error_buf[CURL_ERROR_SIZE] = "";

	curl_easy_setopt(curl, CURLOPT_POSTFIELDS, msg_out);
	http_c.header_list = NULL;
	http_c.header_list = curl_slist_append(http_c.header_list, "Accept:");
	if (!http_c.header_list) return -1;
	http_c.header_list = curl_slist_append(http_c.header_list, "User-Agent: easycwmp");
	if (!http_c.header_list) return -1;
	http_c.header_list = curl_slist_append(http_c.header_list, "Content-Type: text/xml; charset=\"utf-8\"");
	if (!http_c.header_list) return -1;
	if (config->acs->http100continue_disable) {
		http_c.header_list = curl_slist_append(http_c.header_list, "Expect:");
		if (!http_c.header_list) return -1;
	}
	if (msg_out) {
		DDF("+++ SEND HTTP REQUEST +++\n");
		DDF("%s", msg_out);
		DDF("--- SEND HTTP REQUEST ---\n");
		curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long) strlen(msg_out));
		http_c.header_list = curl_slist_append(http_c.header_list, "SOAPAction;");
		if (!http_c.header_list) return -1;
	}
	else {
		DDF("+++ SEND EMPTY HTTP REQUEST +++\n");
		curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, 0);
	}
	curl_easy_setopt(curl, CURLOPT_FAILONERROR, true);
	curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error_buf);

	curl_easy_setopt(curl, CURLOPT_HTTPHEADER, http_c.header_list);

	curl_easy_setopt(curl, CURLOPT_WRITEDATA, msg_in);

	*msg_in = (char *) calloc (1, sizeof(char));

	res = curl_easy_perform(curl);

	if (http_c.header_list) {
		curl_slist_free_all(http_c.header_list);
		http_c.header_list = NULL;
	}

	if (error_buf[0] != '\0')
		log_message(NAME, L_NOTICE, "LibCurl Error: %s\n", error_buf);

	if (!strlen(*msg_in)) {
		FREE(*msg_in);
	}
	
	long httpCode = 0;
	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);

	if (httpCode == 302 || httpCode == 307) {
		curl_easy_getinfo(curl, CURLINFO_REDIRECT_URL, &http_redirect_url);
		if ((http_redirect_url = strdup(http_redirect_url)) == NULL)
			return -1;
		http_client_exit();
		if (http_client_init()) {
			D("receiving http redirect: re-initializing http client failed\n");
			FREE(http_redirect_url);
			return -1;
		}
		FREE(http_redirect_url);
		FREE(*msg_in);
		int redirect = http_send_message(msg_out, msg_in);
		return redirect;
	}

	if (res || (httpCode != 200 && httpCode != 204)) {
		log_message(NAME, L_NOTICE, "sending http message failed\n");
		return -1;
	}

	if (*msg_in) {
		DDF("+++ RECEIVED HTTP RESPONSE +++\n");
		DDF("%s", *msg_in);
		DDF("--- RECEIVED HTTP RESPONSE ---\n");
	} else {
		DDF("+++ RECEIVED EMPTY HTTP RESPONSE +++\n");
	}

	return 0;
}

void
http_server_init(void)
{
	http_digest_init_nonce_priv_key();

	http_s.http_event.cb = http_new_client;

	http_s.http_event.fd = usock(USOCK_TCP | USOCK_SERVER | USOCK_NOCLOEXEC | USOCK_NONBLOCK, "0.0.0.0", config->local->port);
	uloop_fd_add(&http_s.http_event, ULOOP_READ | ULOOP_EDGE_TRIGGER);

	DDF("+++ HTTP SERVER CONFIGURATION +++\n");
	if (config->local->ip)
		DDF("ip: '%s'\n", config->local->ip);
	else
		DDF("NOT BOUND TO IP\n");
	DDF("port: '%s'\n", config->local->port);
	DDF("--- HTTP SERVER CONFIGURATION ---\n");

	log_message(NAME, L_NOTICE, "http server initialized\n");
}

static void
http_new_client(struct uloop_fd *ufd, unsigned events)
{
	struct timeval t;
	int cr_auth_type = config->local->cr_auth_type;
	char buffer[BUFSIZ];
	char *auth_digest, *auth_basic;
	int8_t auth_status = 0;
	FILE *fp;
	int cnt = 0;

	t.tv_sec = 60;
	t.tv_usec = 0;

	for (;;) {
		int client = -1, last_client = -1;
		while ((last_client = accept(ufd->fd, NULL, NULL)) > 0) {
			if (client > 0)
				close(client);
			client = last_client;
		}
		/* set one minute timeout */
		if (setsockopt(ufd->fd, SOL_SOCKET, SO_RCVTIMEO, (char *)&t, sizeof t)) {
			DD("setsockopt() failed\n");
		}
		if (client <= 0) {
			break;
		}
		fp = fdopen(client, "r+");
		if (fp == NULL) {
			close(client);
			continue;
		}

		DDF("+++ RECEIVED HTTP REQUEST +++\n");
		*buffer = '\0';
		while (fgets(buffer, sizeof(buffer), fp)) {
			char *username = config->local->username;
			char *password = config->local->password;
			if (!username || !password) {
				// if we dont have username or password configured proceed with connecting to ACS
				auth_status = 1;
			}
			else if ((cr_auth_type == AUTH_DIGEST) && (auth_digest = strstr(buffer, "Authorization: Digest "))) {
				if (http_digest_auth_check("GET", "/", auth_digest + strlen("Authorization: Digest "), REALM, username, password, 300) == MHD_YES)
					auth_status = 1;
				else {
					auth_status = 0;
					log_message(NAME, L_NOTICE, "Connection Request authorization failed\n");
				}
			}
			else if ((cr_auth_type == AUTH_BASIC) && (auth_basic = strstr(buffer, "Authorization: Basic "))) {
				if (http_basic_auth_check(buffer ,username, password) == MHD_YES)
					auth_status = 1;
				else {
					auth_status = 0;
					log_message(NAME, L_NOTICE, "Connection Request authorization failed\n");
				}
			}
			if (buffer[0] == '\r' || buffer[0] == '\n') {
				/* end of http request (empty line) */
				goto http_end;
			}
		}

http_end:
		if (*buffer) {
			fflush(fp);
			if (auth_status) {
				fputs("HTTP/1.1 200 OK\r\n", fp);
				fputs("Content-Length: 0\r\n", fp);
				fputs("Connection: close\r\n", fp);
				DDF("+++ HTTP SERVER CONNECTION SUCCESS +++\n");
				log_message(NAME, L_NOTICE, "ACS initiated connection\n");
				cwmp_connection_request(EVENT_CONNECTION_REQUEST);
			}
			else {
				fputs("HTTP/1.1 401 Unauthorized\r\n", fp);
				fputs("Content-Length: 0\r\n", fp);
				fputs("Connection: close\r\n", fp);
				if (cr_auth_type == AUTH_BASIC) {
					http_basic_auth_fail_response(fp, REALM);
				}
				else {
					http_digest_auth_fail_response(fp, "GET", "/", REALM, OPAQUE);
				}
				fputs("\r\n", fp);
			}
			fputs("\r\n", fp);
		}
		else {
			fputs("HTTP/1.1 409 Conflict\r\nConnection: close\r\n\r\n", fp);
		}
		fflush(fp);
		fclose(fp);
		close(client);
		DDF("--- RECEIVED HTTP REQUEST ---\n");
		break;
	}
}
