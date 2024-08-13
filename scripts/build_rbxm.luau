
-- build rbxm
-- wrapper around roblox.serializeModel because it makes it nicer to use
-- for what im doing :3

local roblox = require("@lune/roblox")

local function build_rbxm(...: roblox.Instance): string
	return roblox.serializeModel({ ... })
end

return build_rbxm