
-- diff to tbl
-- module for converting a github .diff file to a lua table
-- containg the names of each library changed

local SCRIPTS_THAT_IF_CHANGED_ALL_TESTS_MUST_BE_RAN = {}
local GMATCH = string.gmatch
local diff_to_tbl = {}

function diff_to_tbl.scripts(diff: string): ({ string }, { [string]: boolean })
	local changed_array = {}
	local changed_set = {}
	
	for script in GMATCH(diff, "diff %-%-git a/scripts/([^/%.]+)") do
		if not changed_set[script] then
			table.insert(changed_array, script)
			changed_set[script] = true
		end
	end
	return changed_array, changed_set
end

function diff_to_tbl.libs(diff: string): ({ string }, { [string]: boolean })
	local changed_array = {}
	local changed_set = {}
	
	for lib in GMATCH(diff, "diff %-%-git a/libs/([^/]+)") do
		if not changed_set[lib] then
			table.insert(changed_array, lib)
			changed_set[lib] = true
		end
	end
	return changed_array, changed_set
end

return table.freeze(diff_to_tbl)