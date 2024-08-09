
-- find library in string
-- finds a library in a string, if it can't it'll return nil

local fs = require("@lune/fs")

local LIBS = fs.readDir("libs")

local function FIND_LIB_IN_STR(str: string): string?
	-- replace search in future w a prefix tree if it turns out to be too slow one day
	for _, lib in LIBS do
		if string.find(str, lib, 1, true) then
			return lib
		end
	end
	return nil
end

return FIND_LIB_IN_STR