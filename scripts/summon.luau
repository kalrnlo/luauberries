
-- summon
-- small wrapper around lunes process.spawn, that makes it actually error
-- and sets the shell by default to bash

local process = require("@lune/process")

local SPAWN_OPTS = { shell = "powershell" } :: process.SpawnOptions
local ENV = table.clone(process.env)
local SPAWN = process.spawn

local function summon(
	process: string,
	args: { string }?
): string
	local result = SPAWN(process, args, {
		shell = "bash",
		env = ENV
	})
 
	if not result.ok then
		error(result.stderr, 2)
	end
	return result.stdout
end

return summon
