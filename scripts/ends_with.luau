
-- ends with
-- utility func for checking if a string ends with a diffrent string

local SUB = string.sub

-- ik its unneeded to give string.sub a variable, but im just doing it to remain consistent
local function ends_with(str: string, ends_with: string): boolean
	return SUB(str, #str - (#ends_with - 1)) == ends_with
end

return ends_with