--!native

-- get keyinfo
-- function for getting the keyinfo for a gem

local t = require("../types")

local ERR_CANNOT_FIND_GEM = "[CHEST] cannot %s gem %s because it doesnt exist in chest %s"

local function GET_KEYINFO(local_gem: t.Gem, error_action: string): t.KeyInfo
	local chest = local_gem.chest
	local name = local_gem.name
	local keyinfo = chest.local_keys[name]

	if keyinfo then
		return keyinfo :: any
	else
		error(string.format(ERR_CANNOT_FIND_GEM, error_action, name, chest.name), 2)
	end
end

return GET_KEYINFO