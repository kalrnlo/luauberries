
-- implementer
-- a wrapper for easily implementing properties and methods
-- in lune to mock roblox stuffs

local roblox = require("@lune/roblox")

local CLASS_TO_IMPLEMENTOR = {}

local function implementor(class: string, f: () -> ()): () -> ()
	local HAS_IMPLEMENTED = false

	return function()
		if HAS_IMPLEMENTED then
			error("")
		else
			f()
		end
	end
end

return implementor
