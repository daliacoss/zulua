require("zulip")
require("cfg")

if cfg.key and cfg.email then
	client = zulip.Client:new(cfg.email, cfg.key)
else
	print("Error: must set up cfg.lua")
	return
end

if not arg[1] then
	print("Error: must include recipient address")
	return
end

response = client:send_private_message(arg[1],
	"This is a test message from Zulua, the unofficial Zulip API binding for Lua. "..
	"http://github.com/deckman/zulua"
)

print(response.result, response.msg)