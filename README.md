Zulua
=====

Zulua is a Lua binding of the Zulip API. in addition to extending the basic functionality of the RESTful api (i.e., registering and accessing event queues), it provides functions that streamline common tasks like sending and responding to private messages.

requirements
------------
lua 5.1  
lua-cURL (not to be confused with luacurl)  
dkjson (included)

API
---
**zulip.Client**  
client used by your zulip bot.  
properties:  
email (string) -- bot email address  
key (string) -- bot api key  
queue_id (number) -- current event queue id  
last_event_id (number) -- last event id  
curl -- easy cURL instance

**zulip.Client:new(email, key)**  
instantiate a new zulip client.  
arguments:  
email (string) -- bot email address  
key (string) -- bot api key

**zulip.Client:send_message(msg)**  
send a private or stream message.  
arguments:  
msg.to (string) -- name of stream  
msg.type (string) -- either "stream" or "private"  
msg.content (string, number, boolean) -- message content  
msg.subject (string, number, boolean) -- only used if msg.type is "stream"

**zulip.Client:send_private_message(to, content)**  
send a private message.  
equivalent to `send_message({to=to, content=content, type="private"{)`

**zulip.Client:send_stream_message(to, content, subject)**  
send a stream message.  
equivalent to `send_message({to=to, content=content, subject=subject type="stream"{)`


**zulip.Client:call_on_each_event(callback, event_types)**  
blocking function that runs a callback on each event of the requested types.  
arguments:  
callback (function) -- callback with a signature of function(dataTable) (see official api reference for dataTable spec)  
event_types (table) -- zero or more of "message", "pointer", "subscriptions", "realm"

**zulip.Client:call_on_each_event(callback, event_types)**  
equivalent to `call_on_each_message(callback, {"message"})`

**zulip.Client:register_queue(event_types, apply_markdown)**  
register an event queue to self.queue_id and return response.  
arguments:  
event_types (table) -- zero or more of "message", "pointer", "subscriptions", "realm"  
apply_markdown (boolean)

**zulip.Client:get_events_from_queue(reregister_if_dead, queue_id, last_event_id, dont_block)**  
get latest events from queue as response table.  
arguments:  
reregister_if_dead (boolean) -- call register_queue if queue_id does not exist  
queue_id (numeber) -- default to self.queue_id  
last_event_id -- default to self.last_event_id  
dont_block -- immediately receive either events or heartbeat

examples
--------
usage for the included sample programs:

`lua5.1 examples/send_test_msg.lua RECIPIENT_ADDRESS`  
`lua5.1 examples/print_each_msg.lua`

