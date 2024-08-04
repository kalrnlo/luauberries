--!native

-- isempty
-- simple utility function for telling if a table is empty or not

local function isempty(tbl: { [unknown]: unknown }): boolean
	for _ in tbl do
		return false
	end
	return true
end

return isempty