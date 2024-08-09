
-- diff to tbl
-- module for converting a github .diff file to a lua table
-- containg the names of each library changed

local process = require("@lune/process")
local net = require("@lune/net")

local PROCESS_URL = process.args[1]
local GMATCH = string.gmatch
local MATCH = string.match

local function MATCH_DIFF_LINE(line: string): string?
	return MATCH(line, "^diff %+%+%+ a/(.+)") or 
		MATCH(line, "^diff %-%-%- a/(.+)") or
		MATCH(line, "^diff %+%+%+ b/(.+)") or
		MATCH(line, "^diff %-%-%- b/(.+)")
end

local function DIFF_TO_TBL(diff: string): { string }
    local libs_changed = {}
    
    for line in diff:gmatch("[^\r\n]+") do
        local lib_path = MATCH_DIFF_LINE(line)
        if path then
            local libName = path:match("^libs/([^/]+)")
            if libName and not table.find(libs_changed, libName) then
                table.insert(libs_changed, libName)
            end
        end
    end
    
    return libNames
end

if PROCESS_URL then
	locla 
end
