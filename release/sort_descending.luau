
-- sort descending
-- utility func for sorting an array of strings in descending order
-- based on len

local function sort_descending(t: { string }): { string }
	table.sort(t, function(a, b)
		return #a > #b
	end)
	return t
end

return sort_descending
