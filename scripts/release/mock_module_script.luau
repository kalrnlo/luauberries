
-- impl module source prop
-- func that when called implements the source property to module script instances

local roblox = require("@lune/roblox")

local SOURCES = {} :: { [roblox.Instance]: string }
local HAS_IMPLEMENTED = false

local function impl_module_source_prop()
	if not HAS_IMPLEMENTED then
		roblox.implementProperty(
			"ModuleScript", "Source", 
			function(module: any)
				return SOURCES[module] or ""
			end,
			function(module: any, new_val: string)
				if type(new_val) == "string" then
					SOURCES[module] = new_val
				else
					error("[MODULE SCRIPT] property \"Source\" must be of type string")
				end
			end
		)
	else
		error("[IMPL MODULE SOURCE PROP] \"Source\" property for class \"ModuleScript\" has already been implemented")
	end
end

return impl_module_source_prop
