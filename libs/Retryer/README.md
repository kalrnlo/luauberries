### Retryer

Module for easily retrying functions

#### example
```luau
local StarterGui = game:GetService("StarterGui")
local retryer = require("retryer")

local SET_CORE = StarterGui.SetCore

local function foo(n: number)
    return n + 1
end

-- delay between retrys, max retrys, function to retry, function args
local success, added = retryer.delay(10, 20, foo, 1)

-- max retrys, function to retry, function args
local success, other_added = retryer(20, foo, 1)
other_added -= 3

-- infretry is useful for stuff like StarterGui:SetCore()
-- where it will fail for a bit unless ur script is parented to StarterGui
retryer.infretry(SET_CORE, "ResetButtonCallback", false)

```
