-- Copyright 2015 OVH
-- Author: Simon Lelievre <sim@ovh.net>
-- Licensed to the public under the ?

local p   = require 'posix'
local sig = require "posix.signal"
local overthebox = require 'overthebox'


local json      = require("luci.json")
local uci       = require("luci.model.uci").cursor()

function error(str)
        p.syslog( p.LOG_ERR, str)
end
function log(str)
        p.syslog( p.LOG_NOTICE, str)
end
function debug(str)
        p.syslog( p.LOG_DEBUG, str)
end

run = true
local function handle_exit()
	log("end")
	run = false
end
sig.signal (sig.SIGINT,  handle_exit)

overthebox.debug = true

local rcode, ret = overthebox.get_service()
if rcode == 200 and ret.service then
	overthebox.confirm_service(ret.service)
end

overthebox.notify_boot()

local delay = 10
while run do
	log("run")
	local rcode, ret = overthebox.status()
	
	if rcode == 401 then
		rcode, ret = overthebox.subscribe()
		if rcode ~= 200 then
			error("can not subscribe to api : " .. ret.error )	
		end
	elseif rcode == 200 and ret.action then
		local actionreturn 
		local msg 
		print("I do : "..ret.action)
		
		if     ret.action == "update" then
			actionreturn, msg = overthebox.opkg_update()	
		elseif ret.action == "upgradable" then
			actionreturn, msg = overthebox.opkg_upgradable()
		elseif ret.action == "install" then
			actionreturn, msg = overthebox.opkg_install(ret.param)
		elseif ret.action == "upgrade" then
                        actionreturn, msg = overthebox.upgrade()
		elseif ret.action == "sysupgrade" then
                        -- actionreturn, msg = overthebox.sysupgrade()
			actionreturn = true
                        msg = "ok"
		elseif ret.action == "configure" then
			actionreturn, msg = overthebox.config()
		elseif ret.action == "reboot" then
			-- actionreturn, msg = overthebox.reboot()
			actionreturn = true
			msg = "ok"
		elseif ret.action == "wait" then
			delay = ret.arguments.delay or 10
		end
		if actionreturn ~= nil then
			overthebox.confirm_action(ret.id, actionreturn, msg)
		end
	end

        p.sleep(delay)
end

overthebox.notify_shutdown()

