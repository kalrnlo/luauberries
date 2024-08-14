
-- summon
-- small wrapper around lunes process.spawn, that makes it actually error
-- and sets the shell by default to bash

local process = require("@lune/process")

local SPAWN = process.spawn
local OPTS = {
	shell = if process.os == "windows" then "powershell" else "bash",
	env = process.env
}

local function summon(
	process: string,
	args: string?
): string
	local result = SPAWN(process, { args or "" }, OPTS)
 
	if not result.ok then
		error(result.stderr, 2)
	end
	return result.stdout
end

return summon
