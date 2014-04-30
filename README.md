Zulua
=====

Zulua is a Lua binding of the Zulip API. in addition to extending the basic functionality of the RESTful api (i.e., registering and accessing event queues), it provides functions that streamline common tasks like sending and responding to private messages.

requirements
------------
lua 5.1
lua-cURL (not to be confused with luacurl)
dkjson (included)

api
---
**zulip.Client:new(email, key)**
instantiate a new zulip client.
arguments:
  email -- bot email address
  key -- bot api key

examples
--------
usage for the included sample programs (make sure to run them from within examples/ !):

`lua5.1 send_test_msg.lua RECIPIENT_ADDRESS`
`lua5.1 print_each_msg.lua`
