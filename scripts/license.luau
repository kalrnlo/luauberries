
-- license
-- generates a code comment license header

local fs = require("@lune/fs")

local GSUB = string.gsub
local SUB = string.sub

local function LICENSE_REPLACE(str: string): string
	return `\n-- {SUB(str, 2)}`
end

return `-- MIT License\n{GSUB(SUB(fs.readFile("LICENSE"), 14), "\n%a+", LICENSE_REPLACE)}`