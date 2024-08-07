
-- license
-- generates a code comment license header

local fs = require("@lune/fs")

local function LICENSE_REPLACE(str: string): string
	return `\n-- {string.sub(str, 2)}`
end

return `-- MIT License\n{string.gsub(string.sub(fs.readFile("LICENSE"), 14), "\n%a+", LICENSE_REPLACE)}`