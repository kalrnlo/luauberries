# Retryer

A utility for easily retrying functions

```luau
local StarterGui = game:GetService("StarterGui")
local retryer = require("retryer")

retryer.inf(10, StarterGui.SetCore, "ResetButtonCallback", false)

```

## Methods

### `__call`

Retrys a function x times, based on how many retries its allowed to make

```luau
-- max retrys, function to retry, function args
local success, added = retryer(20, function(n: number)
    return n + 3
end, 1)

if success then
    other_added -= 3
else
    print("add failure!")
end
```

### `delay`

Retrys a function x times, based on how many retries its allowed to make.
With a delay in between thats provided as the first argument

```luau
-- delay between retrys, max retrys, function to retry, function args
local success, added = retryer.delay(20, 10, function(n: number)
    return n + 3
end, 1)

if success then
    other_added -= 3
else
    print("delayed add failure!")
end
```

> [!DANGER]
> The infinite methods can infinitely yield so its reccomended to not use them unless you have to
> such as with [`StarterGui:SetCore()`](https://create.roblox.com/docs/reference/engine/classes/StarterGui#SetCore)

### `inf`

Works like [`__call`](#call), except that it infinitely retries until it succeeds

```luau
-- function to retry, function args
local added = retryer(function(n: number)
    return n + 3
end, 1)

other_added -= 3
```

### `infdelay`

Works like [`delay`](#delay), except that it infinitely retries until it succeeds

```luau
local StarterGui = game:GetService("StarterGui")

retryer.infdelay(10, StarterGui.SetCore, "ResetButtonCallback", false)
```

