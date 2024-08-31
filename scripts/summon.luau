
-- summon
-- small wrapper around lunes process.spawn, that makes it actually error
-- and sets the shell by default to bash

local process = require("@lune/process")

local SPAWN = process.spawn
local ENV = table.clone(process.env)
local OPTS = {
	shell = if process.os == "windows" then "powershell" else "bash",
	env = ENV
}

local function summon(process: string, args: string?): string
	local result = SPAWN(process, { args or "" }, OPTS)
 
	if not result.ok then
		error(result.stderr, 2)
	end
	return result.stdout
end

ENV.GH_TOKEN = ENV.GITHUB_TOKEN

return summon
