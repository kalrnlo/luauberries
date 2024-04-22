--!strict

-- config merge
-- utility function for merging a new config, with the existing config
-- @kalrnlo
-- 22/04/2024

-- TODO: when luau gets typefunctions change new_configs type to be a type function that makes every key
-- in config optional
local function config_merge<config>(config: config, new_config: {[unknown]: unknown})
    for key, value in config do
        if new_config[key] then
            config[key] = new_config[key]
        end
    end
    return config
end

return config_merge