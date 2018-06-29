#!/bin/sh
# Copyright (C) 2012-2014 PIVA Software <www.pivasoftware.com>
# 	Author: MOHAMED Kallel <mohamed.kallel@pivasoftware.com>
# 	Author: AHMED Zribi <ahmed.zribi@pivasoftware.com>
# 	Author: ANIS ELLOUZE <anis.ellouze@pivasoftware.com>
# Copyright (C) 2011-2012 Luka Perkov <freecwmp@lukaperkov.net>

. /lib/functions.sh
. /usr/share/libubox/jshn.sh
. /usr/share/easycwmp/defaults

UCI_GET="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} get"
UCI_SET="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} set"
UCI_SHOW="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} show"
UCI_COMMIT="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} commit"
UCI_ADD="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add"
UCI_DELETE="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} delete"
UCI_ADD_LIST="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list"
UCI_DEL_LIST="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} del_list"
UCI_REVERT="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} revert"
UCI_CHANGES="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} changes"
UCI_BATCH="/sbin/uci -q ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} batch"

DOWNLOAD_DIR="/tmp/easycwmp_download"
EASYCWMP_PROMPT="easycwmp>"
set_fault_tmp_file="/tmp/.easycwmp_set_fault_tmp"
apply_service_tmp_file="/tmp/.easycwmp_apply_service"
set_command_tmp_file="/tmp/.easycwmp_set_command_tmp"
FUNCTION_PATH="/usr/share/easycwmp/functions"
NOTIF_PARAM_VALUES="/tmp/.easycwmp_notif_param_value"
easycwmp_config_changed=""
uci_change_packages=""
uci_change_services=""
g_fault_code=""

prefix_list=""
entry_execute_method_list=""
entry_execute_method_list_forcedinform=""
entry_method_root=""

g_entry_param=""
g_entry_method=""
g_entry_arg=""
# Fault codes
E_REQUEST_DENIED="1"
E_INTERNAL_ERROR="2"
E_INVALID_ARGUMENTS="3"
E_RESOURCES_EXCEEDED="4"
E_INVALID_PARAMETER_NAME="5"
E_INVALID_PARAMETER_TYPE="6"
E_INVALID_PARAMETER_VALUE="7"
E_NON_WRITABLE_PARAMETER="8"
E_NOTIFICATION_REJECTED="9"
E_DOWNLOAD_FAILURE="10"
E_UPLOAD_FAILURE="11"
E_FILE_TRANSFER_AUTHENTICATION_FAILURE="12"
E_FILE_TRANSFER_UNSUPPORTED_PROTOCOL="13"
E_DOWNLOAD_FAIL_MULTICAST_GROUP="14"
E_DOWNLOAD_FAIL_CONTACT_SERVER="15"
E_DOWNLOAD_FAIL_ACCESS_FILE="16"
E_DOWNLOAD_FAIL_COMPLETE_DOWNLOAD="17"
E_DOWNLOAD_FAIL_FILE_CORRUPTED="18"
E_DOWNLOAD_FAIL_FILE_AUTHENTICATION="19"

easycwmp_usage() {
cat << EOF
USAGE: $1 command [parameter] [values]
command:
  get [value|notification|name]
  set [value|notification]
  apply [value|notification|object|service]
  add [object]
  delete [object]
  download
  factory_reset
  reboot
  inform [parameter|device_id]
  --json-input
EOF
}

__arg1=""; __arg2=""; __arg3=""; __arg4=""; __arg5="";

json_get_opt() {
	__arg1=""; __arg2=""; __arg3=""; __arg4=""; __arg5="";
	
	json_init
	json_load "$1"
	local command class
	json_get_var command command
	case "$command" in
		set|get|add|delete)
			json_get_var class class
			json_get_var __arg1 parameter
			json_get_var __arg2 argument
			if [ "$class" != "" ]; then
				action="$command""_$class"
			else
				action="$command""_value"
			fi
			;;
		download)
			action="download"
			json_get_var __arg1 url
			json_get_var __arg2 file_type
			json_get_var __arg3 file_size
			json_get_var __arg4 user_name
			json_get_var __arg5 password
			;;
		factory_reset|reboot)
			action="$command"
			;;
		inform)
			json_get_var class class
			if [ "$class" != "" ]; then
			action="inform_$class"
			else
				action="inform_parameter"
			fi
			;;
		apply)
			json_get_var class class
			json_get_var __arg1 argument
			if [ "$class" != "" ]; then
				action="apply_$class"
			else
				action="apply_value"
			fi
			;;
		end)
			action="end"
			echo "$EASYCWMP_PROMPT"
			;;
		update_value_change)
			action="update_value_change"
			;;
		check_value_change)
			action="check_value_change"
			;;
		exit)
			exit 0
			;;
	esac	
}

case "$1" in
	set|get|add|delete)
		if [ "$2" = "notification" -o "$2" = "value" -o "$2" = "name" -o "$2" = "object" ]; then
			__arg1="$3"
			__arg2="$4"
			action="$1_""$2"
		else
			__arg1="$2"
			__arg2="$3"
			action="$1""_value"
		fi
		;;
	download)
		action="download"
		__arg1="$2"
		__arg2="$3"
		__arg3="$4"
		__arg4="$5"
		__arg5="$6"
		;;
	factory_reset|reboot)
		action="$1"
		;;
	inform)
		if [ "$2" != "" ]; then
		action="inform_$2"
		else
			action="inform_parameter"
		fi
		;;
	apply)
		if [ "$2" != "" ]; then
			__arg1="$3"
			action="apply_$2"
		else
			__arg1="$2"
			action="apply_value"
		fi
		;;
	--json-input)
		action="json_input"
		;;
	update_value_change)
		action="update_value_change"
		;;
	check_value_change)
		action="check_value_change"
		;;
	*)
		easycwmp_usage $0
		;;
esac


if [ -z "$action" ]; then
	echo invalid action \'$1\'
	exit 1
fi

dmscripts=`ls $FUNCTION_PATH`
. $FUNCTION_PATH/root
for dms in $dmscripts; do
	[ "$dms" != "root" ] && . $FUNCTION_PATH/$dms
done

prefix_list="$DMROOT. $prefix_list"
entry_execute_method_list="$entry_method_root $entry_execute_method_list"

handle_action() {
	if [ "$action" = "get_value" ]; then
		(common_entry_get_value "$__arg1")
		local fault="$?"
		if [ "$fault" != "0" ]; then
			common_json_output_fault "$__arg1" "$((fault+9000))"
		fi
		return
	fi
	
	if [ "$action" = "get_name" ]; then
		[ "`echo $__arg2 | awk '{print tolower($0)}'`" = "false" ] &&  __arg2="0"
		[ "`echo $__arg2 | awk '{print tolower($0)}'`" = "true" ] &&  __arg2="1"
		if [ "$__arg2" != "0" -a "$__arg2" != "1" ]; then
			common_json_output_fault "$__arg1" "$((E_INVALID_ARGUMENTS+9000))"
			return
		fi
		(common_entry_get_name "$__arg1" "$__arg2")
		local fault="$?"
		if [ "$fault" != "0" ]; then
			common_json_output_fault "$__arg1" "$((fault+9000))"
		fi
		return
	fi
	
	if [ "$action" = "get_notification" ]; then
		(common_entry_get_notification "$__arg1")
		local fault="$?"
		if [ "$fault" != "0" ]; then
			common_json_output_fault "$__arg1" "$((fault+9000))"
		fi
		return
	fi
	
	if [ "$action" = "set_value" ]; then
		(common_entry_set_value "$__arg1" "$__arg2")
		local fault="$?"
		if [ "$fault" != "0" ]; then
			common_set_parameter_fault "$__arg1" "$((fault+9000))"
		fi
		return
	fi
	
	if [ "$action" = "set_notification" ]; then
		(common_entry_set_notification "$__arg1" "$__arg2")
		local fault="$?"
		if [ "$fault" != "0" ]; then
			common_set_parameter_fault "$__arg1" "$((fault+9000))"
		fi
		return
	fi
	
	if [ "$action" = "download" ]; then
# TODO: check firmaware size with falsh to be improved  
		dl_size=`df  |grep  "/tmp$" | awk '{print $4;}'`
		[ -n "$dl_size" ] && dl_size_byte=$((${dl_size}*1024))
		if [ -n "$dl_size" -a "$dl_size_byte" -lt "$__arg3" ]; then
			let fault_code=9000+$E_DOWNLOAD_FAILURE
			common_json_output_fault "" "$fault_code"
		else 
			rm -rf $DOWNLOAD_DIR 2> /dev/null
			mkdir -p $DOWNLOAD_DIR
			local dw_url="$__arg1"
			[ "$__arg4" != "" -o "$__arg5" != "" ] && dw_url=`echo "$__arg1" | sed -e "s@://@://$__arg4:$__arg5\@@g"`
			wget -P $DOWNLOAD_DIR "$dw_url"
			fault_code="$?"
			if [ "$fault_code" != "0" ]; then
				rm -rf $DOWNLOAD_DIR 2> /dev/null
				let fault_code=9000+$E_DOWNLOAD_FAILURE
				common_json_output_fault "" "$fault_code"
			else
				common_json_output_status "1"
			fi
		fi
		return
	fi
	if [ "$action" = "apply_download" ]; then
		if [ "$__arg1" = "3 Vendor Configuration File" ]; then 
			dwfile=`ls $DOWNLOAD_DIR`
			if [ "$dwfile" != "" ]; then
				dwfile="$DOWNLOAD_DIR/$dwfile"
				if [ ${dwfile%.gz} != $dwfile -o ${dwfile%.bz2} != $dwfile ]; then
					sysupgrade --restore-backup $dwfile
					fault_code="$?"
				else
					/sbin/uci import < $dwfile
					fault_code="$?"
					[ "$fault_code" = "0" ] && $UCI_COMMIT
				fi
				if [ "$fault_code" != "0" ]; then
					let fault_code=$E_DOWNLOAD_FAIL_FILE_CORRUPTED+9000
					common_json_output_fault "" "$fault_code"
				else
					sync
					reboot
					common_json_output_status "1"
				fi
			else
				let fault_code=$E_DOWNLOAD_FAILURE+9000
				common_json_output_fault "" "$fault_code"
			fi
		elif [ "$__arg1" = "1 Firmware Upgrade Image" ]; then
			local gr_backup=`grep "^/etc/easycwmp/\.backup\.xml" /etc/sysupgrade.conf`
			[ -z $gr_backup ] && echo "/etc/easycwmp/.backup.xml" >> /etc/sysupgrade.conf
			dwfile=`ls $DOWNLOAD_DIR`
			if [ "$dwfile" != "" ]; then
				dwfile="$DOWNLOAD_DIR/$dwfile"
				/sbin/sysupgrade $dwfile
				fault_code="$?"
				if [ "$fault_code" != "0" ]; then
					let fault_code=$E_DOWNLOAD_FAIL_FILE_CORRUPTED+9000
					common_json_output_fault "" "$fault_code"
				else
					common_json_output_status "1"
				fi
			else
				let fault_code=$E_DOWNLOAD_FAILURE+9000
				common_json_output_fault "" "$fault_code"
			fi
		else
			common_json_output_fault "" "$(($E_INVALID_ARGUMENTS+9000))"
		fi
		rm -rf $DOWNLOAD_DIR 2> /dev/null
		return
	fi
	if [ "$action" = "factory_reset" ]; then
		if [ "`which jffs2_mark_erase`" != "" ]; then
			jffs2_mark_erase "rootfs_data"
		else
			/sbin/jffs2mark -y
		fi
		sync
		reboot
	fi
	
	if [ "$action" = "reboot" ]; then
		sync
		reboot
	fi
	
	if [ "$action" = "apply_notification" -o "$action" = "apply_value" ]; then
		if [ ! -f "$set_fault_tmp_file" ]; then
			local rev=""
			while read line; do
				[ -z "$line" ] && continue
				local param=${line%%<delim>*}
				local setcmd=${line#*<delim>}
				setcmd=${setcmd%<delim>*}
				eval "$setcmd"
				local fault="$?"
				if [ "$fault" != "0" ]; then
					rev=1
					common_json_output_fault "$param" "$((fault+9000))"
				fi
			done < $set_command_tmp_file
			if [ -n "$rev" ]; then
				local cfg cfg_reverts=`$UCI_CHANGES | cut -d'.' -f1 | sort -u`
				for cfg in $cfg_reverts; do
					$UCI_REVERT $cfg
				done
			else
				if [ "$action" = "apply_value" ]; then
					while read line; do
						[ -z "$line" ] && continue
						local param=${line%%<delim>*}
						local gtmp=`grep "\"$param\"" $NOTIF_PARAM_VALUES`
						if [ -n "$gtmp" ]; then
							local getcmd=${line##*<delim>}
							local vtmp=`$getcmd`
							json_init
							json_load "$gtmp"
							json_add_string "value" "$vtmp"
							json_close_object
							gtmp=`json_dump`
							sed -i "/$param/s/.*/$gtmp/" $NOTIF_PARAM_VALUES
						fi
					done < $set_command_tmp_file
					common_uci_change_packages_lookup
					$UCI_SET easycwmp.@acs[0].parameter_key="$__arg1"
					common_json_output_status "1"
				fi
				if [ "$action" = "apply_notification" ]; then
					common_uci_change_packages_lookup
					common_json_output_status "0"
				fi
				$UCI_COMMIT
			fi
		else
			cat "$set_fault_tmp_file" 
		fi
		rm -f "$set_fault_tmp_file"
		rm -f "$set_command_tmp_file"
		return
	fi
	if [ "$action" = "apply_object" ]; then
		$UCI_SET easycwmp.@acs[0].parameter_key="$__arg1"
		$UCI_COMMIT
		return
	fi
	if [ "$action" = "apply_service" ]; then
		common_restart_services
		if [ -f "$apply_service_tmp_file" ]; then
			chmod +x "$apply_service_tmp_file"
			/bin/sh "$apply_service_tmp_file"
			rm -f "$apply_service_tmp_file"
		fi
		return
	fi

	if [ "$action" = "add_object" ]; then
		(common_entry_add_object "$__arg1")
		local fault="$?"
		if [ "$fault" != "0" ]; then
			common_json_output_fault "" "$((fault+9000))"
		fi
		return
	fi

	if [ "$action" = "delete_object" ]; then
		(common_entry_delete_object "$__arg1")
		local fault="$?"
		if [ "$fault" != "0" ]; then
			common_json_output_fault "" "$((fault+9000))"
		fi
		return
	fi

	if [ "$action" = "inform_parameter" ]; then
		(common_entry_inform)
		return
	fi
	
	if [ "$action" = "inform_device_id" ]; then
		common_get_inform_deviceid
		return
	fi

	if [ "$action" = "update_value_change" ]; then
		(common_entry_update_value_change)
		return
	fi

	if [ "$action" = "check_value_change" ]; then
		local line param oldvalue
		while read line; do
			json_init
			json_load "$line"
			json_get_var param parameter
			(common_entry_check_value_change $param $oldvalue)
		done < $NOTIF_PARAM_VALUES
		(common_entry_update_value_change)
		return
	fi
	
	if [ "$action" = "json_input" ]; then
		echo "$EASYCWMP_PROMPT"
		while read CMD; do
			[ -z "$CMD" ] && continue
			json_get_opt "$CMD"
			handle_action
		done
		exit 0
	fi
}
handle_action 2>/dev/null
