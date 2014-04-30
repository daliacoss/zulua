require("zulip")
require("cfg")

if cfg.key and cfg.email then
	client = zulip.Client:new(cfg.email, cfg.key)
else
	print("Error: must set up cfg.lua")
	return
end

callback = function(response)
	if response.type == "message" then
		print(
			"Message from " ..
			response.message.sender_full_name ..
			": " ..
			response.message.content
		)
	end
end

--this is a blocking call
response = client:call_on_each_message(callback)
