
-- remove
-- swap removal func for removing the first index,
-- if the value doesnt exist it'll error

local function remove<V>(t: { V }, len: number): V
	local value = t[1]

	if value ~= nil then
		if len ~= 1 then
			t[1] = t[len]
			t[len] = nil
		else
			t[1] = nil
		end
		
		return value
	else
		error("[REMOVE] value not found")
	end
end

return remove