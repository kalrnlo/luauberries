--!strict

-- ConfigMerge
-- utility function for merging a new config, with the existing config
-- @kalrnlo
-- 10/05/2024

-- TODO: when luau gets typefunctions change new_configs type to be a type function that makes every key
-- in config optional
local function config_merge<C, CK, CV>(config: C & { [CK]: CV }, new_config: { [CK]: any }?)
	if new_config then
		for key, value in config :: any do
			local new_value = (new_config :: any)[key]

			if new_value then
				(config :: any)[key] = new_value
			end
		end
	end
	return config
end

return config_merge