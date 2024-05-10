--!strict

-- ConfigMerge
-- utility function for merging a new config, with the existing config
-- @kalrnlo
-- 23/04/2024

-- TODO: when luau gets typefunctions change new_configs type to be a type function that makes every key
-- in config optional
local function config_merge<C, CK, CV>(config: C & { [CK]: CV }, new_config: { [CK]: any }?)
	if new_config then
		for key, value in config :: any do
			if (new_config :: any)[key] then
				(config :: any)[key] = (new_config :: any)[key]
			end
		end
	end
	return config
end

return config_merge