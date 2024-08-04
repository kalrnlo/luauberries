# Retryer

Utility for easily retrying functions

```luau
local StarterGui = game:GetService("StarterGui")
local retryer = require("retryer")

retryer.inf(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)

```

## Methods

### `__call`

Retrys a function x times, based on how many retrys its allowed to make

```luau
local success, added = retryer(20, function(n: number)
    return n + 3
end, 1)

if success then
    added -= 3
else
    print("add failure!")
end
```

### `delay`

Retrys a function x times, based on how many retrys its allowed to make.
With a delay in between thats provided as the first argument

```luau
local success, added = retryer.delay(20, 10, function(n: number)
    return n + 3
end, 1)

if success then
    added -= 3
else
    print("delayed add failure!")
end
```

### `exp`

Retrys a funtion using [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff) x times, based on how many retrys its alowed to make. Same as [`delay`](#delay), except that its second arg is the exponent with the third being `max_attempts`

```luau
local DataStoreService = game:GetService("DataStoreService")

local STORE = DataStoreService:GetDataStore("COINS", "V1")

retryer.exp(5, 2, 6, STORE.UpdateAsync, STORE, "alice", function(_, keyinfo)
    return -math.huge, keyinfo:GetUserIds(), keyinfo:GetMetadata()
end)
```

> [!DANGER]
> The infinite methods can infinitely yield so its reccomended to not use them unless you have to
> such as with [`StarterGui:SetCore()`](https://create.roblox.com/docs/reference/engine/classes/StarterGui#SetCore)

### `inf`

Works like [`__call`](#call), except that it infinitely retrys until it succeeds

```luau
local added = retryer.inf(function(n: number)
    return n + 3
end, 1)

added -= 3
```

### `infdelay`

Works like [`delay`](#delay), except that it infinitely retrys until it succeeds

```luau
local StarterGui = game:GetService("StarterGui")

retryer.infdelay(10, StarterGui.SetCore, "ResetButtonCallback", false)
```

### `infexp`

Works like [`exp`](#exp), except that it infinitely retrys until it succeeds

```luau
local DataStoreService = game:GetService("DataStoreService")

local STORE = DataStoreService:GetDataStore("COINS", "V1")

retryer.exp(5, 2, STORE.UpdateAsync, STORE, "alice", function(_, keyinfo)
    return -math.huge, keyinfo:GetUserIds(), keyinfo:GetMetadata()
end)
```

