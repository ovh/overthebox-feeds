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

#ifndef _EASYCWMP_BACKUP_H__
#define _EASYCWMP_BACKUP_H__

#include <microxml.h>
#define BACKUP_DIR "/etc/easycwmp"
#define BACKUP_FILE BACKUP_DIR"/.backup.xml"

int backup_extract_transfer_complete( mxml_node_t *node, char **msg_out, int *method_id);
int backup_remove_transfer_complete(mxml_node_t *node);
int backup_update_fault_transfer_complete(mxml_node_t *node, int fault_code);
int backup_update_complete_time_transfer_complete(mxml_node_t *node);
int backup_load_event(void);
int backup_remove_event(mxml_node_t *b);
int backup_load_download(void);
int backup_remove_download(mxml_node_t *node);
int backup_save_file(void);
void backup_load(void);
void backup_init(void);
void backup_add_acsurl(char *acs_url);
void backup_check_acs_url(void);
mxml_node_t *backup_check_transfer_complete(void);
mxml_node_t *backup_tree_init(void);
mxml_node_t *backup_add_transfer_complete(char *command_key, int fault_code, char *start_time, int method_id);
mxml_node_t *backup_add_event(int code, char *key, int method_id);
mxml_node_t * backup_add_download(char *key, int delay, char *file_size, char *download_url, char *file_type, char *username, char *password);
int backup_update_all_complete_time_transfer_complete(void);
#endif
