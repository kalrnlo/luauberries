
-- diff reader
-- module for converting a git .diff file to a lua table
-- containg the names of each file changed

local fs = require("@lune/fs")

local DEFAULT_DIFF = if fs.isFile(".diff") then fs.readFile(".diff") else ""
local SCRIPT_FILENAME_WHITELIST = table.freeze({
	"test_runner", "depgraph", "diff_reader"
})
local LIB_FILENAME_BLACKLIST = table.freeze({
	"LIBINFO", "README", "index",
})
local GMATCH = string.gmatch
local diff_reader = {}

function diff_reader.libs(diff: string?): ({ string }, { [string]: boolean })
	local diff = diff or DEFAULT_DIFF
	local changed_array = {}
	local changed_set = {}
	
	for lib, file_or_dir_name in GMATCH(diff, "diff %-%-git a/libs/([^/]+)/([^/%.]+)") do
		if 
			not (file_or_dir_name and table.find(LIB_FILENAME_BLACKLIST, file_or_dir_name)) and 
			not changed_set[lib] 
		then
			table.insert(changed_array, lib)
			changed_set[lib] = true
		end
	end
	return changed_array, changed_set
end

-- checks if any scripts that if changed all tests must be reran, have infact changed
function diff_reader.scripts(diff: string?): boolean
	local diff = diff or DEFAULT_DIFF
	
	for script in GMATCH(diff, "diff %-%-git a/scripts/([^%.]+)") do
		if table.find(SCRIPT_FILENAME_WHITELIST, script) then
			return true
		end
	end
	return false
end

return table.freeze(diff_reader)