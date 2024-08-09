
-- diff to tbl
-- module for converting a github .diff file to a lua table
-- containg the names of each library changed

local GMATCH = string.gmatch

local function diff_to_tbl(diff: string): ({ string }, { [string]: boolean })
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

return diff_to_tbl