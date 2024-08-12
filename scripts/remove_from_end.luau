
-- remove from end
-- utility func for removing a string from the end of another string

local ends_with = require("ends_with")

local SUB = string.sub

local function remove_from_end(str: string, ending: string): string
	return if ends_with(str, ending) then 
			SUB(str, 1, #str - #ending) 
		else 
			str
end

return remove_from_end