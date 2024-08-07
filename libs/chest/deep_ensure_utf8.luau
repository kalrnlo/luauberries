--!native

-- deep ensure utf8
-- utility func for ensuring a value is made up of only valid utf8

local function DEEP_ENSURE_UTF8<Value>(value: Value): boolean
	if type(value) == "string" and utf8.len(value) ~= #value then
		return false
	elseif type(value) == "table" then
		local tbl = value

		for key, value in tbl do
			if not (DEEP_ENSURE_UTF8(value) or DEEP_ENSURE_UTF8(key)) then
				return false
			end
		end
	end

	return true
end

return DEEP_ENSURE_UTF8
