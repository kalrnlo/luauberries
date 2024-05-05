### Config Merge

Utility function for merging a partial version of a config, with the main config

#### example
```lua
-- Module
local config_merge = require("@kalrnlo/ConfigMerge")

local config = {
	rank_refresh_rate = 60,
	groupid = 0,
}

local function init(new_config: typeof(config))
    config_merge(config, new_config)
end

local module = table.freeze {
    config = config,
    init = init,
}

-- Module Consumer
local module = require("Module")

module.init({
	rank_refresh_rate = 60,
	groupid = 31287129,
})
```
