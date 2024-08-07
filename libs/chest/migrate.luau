--!native

-- migrate
-- function for handling migrating save data

local DATA_OPS = require("data_ops")
local t = require("types")

local function MIGRATE(
	chest: t.Chest,
	saveinfo: t.SaveInfo,
	key: string,
	value: t.JSONAcceptable
): (t.LoadStatus, t.JSONAcceptable?)
	local save_version = saveinfo.version
	local migrations = chest.migrations
	local our_version = chest.version
	local new_value: any
	local success

	if not save_version then
		return "SUCCESS", DATA_OPS.CLONE_DEFAULT_VAL(chest, key)
	elseif save_version > our_version then
		-- COULD NOT LOAD VALUE ERROR HERE
		return "SAVE VERSION TOO HIGH", nil
	end

	for nextver = save_version + 1, #migrations do
		local migrator = migrations[nextver]
		
		if not migrator then
			warn(`[CHEST] migration for version {nextver} does not exist cannot migrate`)
			return "MIGRATION NEXT VERSION NOT FOUND", nil
		end
		
		success, new_value = pcall(migrator, new_value)
		
		if not success then
			warn(`[CHEST] migration callback for version {nextver} errored\n\terror: {new_value}`)
			return "MIGRATION CALLBACK ERROR", nil
		end
	end

	return "SUCCESS", new_value
end

return MIGRATE