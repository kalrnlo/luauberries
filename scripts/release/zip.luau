
-- zip
-- utility for zipping folders within lune

local process = require("@lune/process")
local summon = require("../summon")
local fs = require("@lune/fs")

local IS_WINDOWS = process.os == "windows"
local WIN_OUTPUT = "RESULT.zip"
local WIN_ARGS_FORMAT = `%* -DestinationPath {WIN_OUTPUT} -CompressionLevel Optimal`
local UNIX_ARGS_FORMAT = "-9 -r - %*"
local FORMAT = string.format

local function zip(input: string): string
	if IS_WINDOWS then
		summon("Compress-Archive", FORMAT(WIN_ARGS_FORMAT, input))
		local zipped = fs.readFile(WIN_OUTPUT)
		fs.removeFile(WIN_OUTPUT)
		return zipped
	else
		return summon("zip", FORMAT(UNIX_ARGS_FORMAT, input))
	end
end

return zip
