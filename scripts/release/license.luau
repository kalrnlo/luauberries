
-- license
-- generates a code comment license header

local process = require("@lune/process")
local fs = require("@lune/fs")

-- god i HATE carriage returns being included in files on windows
-- i just had a bug occur w darklua failing to convert requires in github actions
-- BECAUSE I DIDNT ACCOUNT FOR CARRIAGE RETURNS NOT EXISTING ON LINUX,
-- AS ALL MY TESTING I DO FOR SCRIPTS IS ON WINDOWS BECAUSE LIKE THATS THE OS I USE
local SUB_AMOUNT = if process.os == "windows" then 14 else 12
local GSUB = string.gsub
local SUB = string.sub

local function LICENSE_REPLACE(str: string): string
	return `\n-- {SUB(str, 2)}`
end

return `-- MIT License\n{GSUB(SUB(fs.readFile("LICENSE"), SUB_AMOUNT), "\n%a+", LICENSE_REPLACE)}`