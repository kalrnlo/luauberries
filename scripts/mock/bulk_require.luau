
-- bulk require
-- util func for bulk requiring every module in a directory

local remove_from_end = require("../remove_from_end")
local fs = require("@lune/fs")

local FORMAT = string.format
local FIND = string.find
local SUB = string.sub

local function bulk_require(dir: string): { [string]: { [any]: any } }
	local _, mock_end  = FIND(dir, "mock", 1, true)

	if not mock_end then
		error("[BULK REQUIRE] could not get mock end")
	end
	local subdir = SUB(dir, mock_end + 2, #dir)

	if not subdir then
		error(`[BULK REQUIRE] subdir not found in dirstring {dir}`)
	end
	local format = `{subdir}/%*`
	local modules = {}

	for _, module in fs.readDir(dir) do
		local name = remove_from_end(module, ".luau")
		modules[name] = (require)(FORMAT(format, name))
	end
	return table.freeze(modules)
end

return bulk_require