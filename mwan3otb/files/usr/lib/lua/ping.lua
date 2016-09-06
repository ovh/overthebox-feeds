-- Copyright 2015 OVH <OverTheBox@ovh.net>
-- Sebastien Duponcheel <sebastien.duponcheel@ovh.net>
--
-- This file is part of OverTheBox for OpenWrt.
--
--    OverTheBox is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    OverTheBox is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with OverTheBox.  If not, see <http://www.gnu.org/licenses/>
--

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------
local base = _G

local posix = require('posix')
local bit = require('bit')
local fs = require("nixio.fs")
local math = require("math")

local _M = {}

local function diff_nsec(t1, t2)
	local ret = ( t2.tv_sec * 1000000000 + t2.tv_nsec) - (t1.tv_sec * 1000000000 + t1.tv_nsec)
	if ret < 0 then
		print("euhh :", t2.tv_sec, t1.tv_sec, t2.tv_nsec, t1.tv_nsec)
		print(( t2.tv_sec * 1000000000 + t2.tv_nsec), (t1.tv_sec * 1000000000 + t1.tv_nsec))
		print(ret)
		os.exit(-1)
	end
	return ret
end

local function uniqueid(bytes)
	local rand = fs.readfile("/dev/urandom", bytes)
	return rand
end

local function checksum(packet)
	local sum = 0
	local pos = 1
	local len = string.len(packet)
	---
	while pos < len do
		sum = sum + packet:byte(pos + 1) * 256 + packet:byte(pos)
		pos = pos + 2
	end
	-- Append last byte
	if pos < len then
		sum = sum + packet:byte(len) * 256
	end
	-- doing complement
	sum = bit.rshift(sum, 16) + bit.band(sum, 0xFFFF)
	sum = sum + bit.rshift(sum, 16)
	--
	local res = bit.bnot(sum)
	res = bit.band(res, 0xFFFF)
	-- return checksum string
	return  string.char(bit.band(res, 0x00FF)) ..
		string.char(bit.band(bit.rshift(res, 8), 0x00FF))
end

local function create_packet(id, payload)
	-- Header is type (8), code (8), checksum (16), id (16), sequence (16)
	local header = string.char(0x08, 0x00) .. string.char(0x00, 0x00) .. id .. string.char(0x00, 0x01)
	-- Calculate the checksum on the data and the dummy header.
	local my_checksum = checksum(header .. payload)
	-- Rebuild the packet header with the checksum
	header = string.char(0x08, 0x00) .. my_checksum .. id .. string.char(0x00, 0x01)
	-- Now that we have the right checksum, we put that in. It's just easier
	-- to make up a new header than to stuff it into the dummy.
	return header .. payload
end

local function receive_ping(fd, packet_id, time_sent, timeout)
	local data, sa, err

	local time = 0
	while (diff_nsec(time_sent, posix.clock_gettime(posix.CLOCK_REALTIME) )/1000) < timeout do
		data, sa, err = posix.recvfrom(fd, 1024)
		if data then
			-- In raw socket we receive ip header in data
			-- First we decode IP header
			local ip_header_version = string.byte(data, 1)
			ip_version = bit.rshift(bit.band(ip_header_version, 0xF0), 4)
			if ip_version == 4 then
				header_length = bit.band(ip_header_version, 0x0F) * 4

				-- Decode ICMP header is type (8), code (8), checksum (16), id (16), sequence (16)
				local r_type = string.byte(data, header_length + 1)

				if r_type == 0 then
					local r_code = string.byte(data, header_length + 2)
					local r_id   = string.byte(data, header_length + 5) .. string.byte(data, header_length + 6)
					local o_id   = string.byte(packet_id, 1) .. string.byte(packet_id, 2)

					if r_id == o_id then
						local time_recieved = posix.clock_gettime(posix.CLOCK_REALTIME)
						if fd then posix.close(fd) end

						if r_code == 0 then
							return true, (diff_nsec(time_sent, time_recieved)/1000000)
						elseif r_code == 3 then
							return false, "Destination Unreachable"
						elseif r_code == 11 then
							return false, "Time Exceeded"
						end
					end
				end
			end
		elseif err and err ~= 11 then
			if fd then posix.close(fd) end
			return false, sa
		end
	end
	if fd then posix.close(fd) end
	return false, "timeout"
end

function _M.send_ping(host, interface, timeout, size)
	if posix.SOCK_RAW and posix.SO_BINDTODEVICE then
		-- Open raw socket
		local fd, err = posix.socket(posix.AF_INET, posix.SOCK_RAW, posix.IPPROTO_ICMP)
		if not fd then return fd, err end

		-- timeout on socket
		local ok, err = posix.setsockopt(fd, posix.SOL_SOCKET, posix.SO_RCVTIMEO, math.floor(timeout/1000), (timeout % 1000) * 1000)
		if not ok then return ok, err end

		-- bind to specific device
		local ok, err = posix.setsockopt(fd, posix.SOL_SOCKET, posix.SO_BINDTODEVICE, interface)
		if not ok then return ok, err end

		-- Create raw ICMP echo (ping) message
		-- https://fr.wikipedia.org/wiki/Internet_Control_Message_Protocol
		local packet_id = uniqueid(2)
		local payload = ""
		if size and tonumber(size) > 0 then
			payload = uniqueid(tonumber(size))
		end
		local data = create_packet(packet_id, payload)

		local time_sent = posix.clock_gettime(posix.CLOCK_REALTIME)
		-- Send message
		local ok, err = posix.sendto(fd, data, { family = posix.AF_INET, addr = host, port = 0 })
		if not ok then return ok, err end
		-- Wait for answer
		return receive_ping(fd, packet_id, time_sent, timeout)
	else
		return false, "not raw socket"
	end
end

return _M

