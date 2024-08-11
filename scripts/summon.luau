
-- summon
-- small wrapper around lunes process.spawn, that makes it actually error
-- and sets the shell by default to bash

local process = require("@lune/process")

local SPAWN_OPTS = { shell = "powershell" } :: process.SpawnOptions
local SPAWN = process.spawn

local function summon(
	process: string,
	args: { string }?,
	opts: process.SpawnOptions?
): string
	local opts = opts or SPAWN_OPTS

	if not opts.shell then
		--opts.shell = "bash"
	end
	local result = SPAWN(process, args, opts)
 
	if not result.ok then
		error(result.stderr, 2)
	end
	return result.stdout
end

return summon
