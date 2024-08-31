
-- roblox
-- initatates all roblox mock services, instances and globals

local bulk_require = require("../bulk_require")

local function roblox()
	bulk_require("scripts/mock/roblox/services")
	bulk_require("scripts/mock/roblox/instances")
	require("globals")
end

return roblox