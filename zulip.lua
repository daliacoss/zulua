--[[
Copyright (c) Decky Coss 2014-2015 (coss@cosstropolis.com)

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice,
this permission notice, and the following disclaimer appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
]]

require("cURL")
json = require("dkjson")

zulip = {}
zulip.Client = {}

function zulip.Client:new(email, key)
	-- args cannot be null
	assert(email, "email and key are required")

	-- metatable
	o = {}
	setmetatable(o, self)

	self.email = email
	self.key = key
	self.__index = self
	self:reset_curl()

	return o
end

function zulip.Client:set_userpwd()
	self.curl:setopt_userpwd(self.email .. ":" .. self.key)
end

function zulip.Client:reset_curl()
	self.curl = cURL.easy_init()
	self:set_userpwd()
	self.mcurl = cURL.multi_init()
	-- self.mcurl:add_handle(self.curl)
end

function zulip.Client:perform_transfer()
	--[[
		perform curl transfer and return server response
	]]

	local d = ""
	self.curl:perform({writefunction=function(str) d=str end, readfunction=function() end})
	return d
	-- for d, t in self.mcurl:perform() do
	-- 	print(d, t)
	-- 	if t == "data" then return d end
	-- end
end

function zulip.Client:send_message(msg)
	--[[
		send a stream or private message.

		params:
		msg (table)
			msg.to (string) - name of stream
			msg.type (string) - either "stream" or "private"
			msg.content (string, number, boolean) - message content
			msg.subject (string, number, boolean) - only used if msg.type is "stream"
	]]

	assert(msg.to, msg.content, msg.type, "msg object requires 'to', 'content', and 'type' fields")

	--strip out any fields we don't need
	data = {
		to=msg.to, content=msg.content, type=msg.type, subject=msg.subject
	}
	self:reset_curl()
	self.curl:setopt_url("https://api.zulip.com/v1/messages")
	self.curl:post(data)

	-- self.mcurl = cURL.multi_init()
	-- self.mcurl:add_handle(self.curl)
	-- for k,v in self.mcurl:perform() do
	-- 	if v == "data" then print(k) end
	-- end

	--try
	d = self:perform_transfer()
	b, rdata = pcall(json.decode, d)
	if b then
		return rdata
	--except
	else
		return {result="error", msg="no data in server response"}
	end
	--return json.decode(self:perform_transfer())
end

function zulip.Client:send_private_message(to, content)
	--[[
		send a private message.

		params:
		to (string) - email address of recipient
		content (string, number, boolean) - message content
	]]

	return self:send_message{to=to, content=content, type="private"}
end

function zulip.Client:send_stream_message(to, content, subject)
	--[[
		send a stream message.

		params:
		to (string) - name of stream
		content (string, number, boolean) - message content
		subject (string, number, boolean) - message subject
	]]

	return self:send_message{to=to, content=content, subject=subject, type="stream"}
end

function zulip.Client:register_queue(event_types, apply_markdown)
	--[[
		register an event queue, which can be accessed with get_event_from_queue.

		params:
		event_types (table) - zero or more of "message", "pointer", "subscriptions", "realm"
		apply_markdown (boolean)
	]]


	function list_to_string(list)
		if not list then return nil end

		head = "["
		body = ""
		foot = "]"

		for k, v in ipairs(list) do
			body = body .. '"' .. v .. '",'
		end

		-- entire string except trailing comma in body
		return head .. body:sub(1, -2) .. foot
	end

	--no need for assertion, as all args are optional
	data = {event_types=list_to_string(event_types), apply_markdown=apply_markdown}

	self:reset_curl()
	self.curl:setopt_url("https://api.zulip.com/v1/register")
	if data then self.curl:post(data) end

	--try
	b, rdata = pcall(json.decode, self:perform_transfer())
	if b then
		self.queue_id = rdata.queue_id
		self.last_event_id = rdata.last_event_id
		return rdata
	--except
	else
		return {result="error", msg="no data in server response"}
	end
end

function zulip.Client:get_events_from_queue(reregister_if_dead, queue_id, last_event_id, dont_block)
	--[[
		get event from specified queue, or from stored Client queue.
		this function will block until timeout or response from the server.
	]]

	if reregister_if_dead == nil then reregister_if_dead = false end
	queue_id = queue_id or self.queue_id
	last_event_id = last_event_id or self.last_event_id
	dont_block_s = "true" and dont_block or "false"

	assert(queue_id, "self.queue_id not set (have you called register_queue?)")
	assert(last_event_id, "self.last_event_id not set (have you called register_queue?)")

	url = "https://api.zulip.com/v1/events?queue_id=%s&last_event_id=%s&dont_block=%s"
	self:reset_curl()
	self.curl:setopt_url(url:format(queue_id, last_event_id, dont_block_s))
	b, rdata = pcall(json.decode, self:perform_transfer())
	--try
	if b then
		--retry if event queue died
		if reregister_if_dead and rdata.msg:find("Bad event queue") then
			self:register_queue()
			return self:get_events_from_queue(true)
		end
		--set last_event_id
		for i, n in ipairs(rdata.events) do
			self.last_event_id = n.id
		end
		return rdata
	--except
	else
		return {result="error", msg="no data in server response"}
	end

	
end

function zulip.Client:call_on_each_event(callback, event_types)
	self:register_queue(event_types)
	print(self.queue_id)
	while true do
		rdata = self:get_events_from_queue(true)
		if rdata.result == "success" then
			for i, n in ipairs(rdata.events) do
				callback(n)
			end
		end
	end
end

function zulip.Client:call_on_each_message(callback)
	self:call_on_each_event(callback, {"message"})
end

return zulip
