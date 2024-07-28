# Ratelimit

Object for handling ratelimits intuitively

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ratelmit = require("ratelimit")

local check_limit = ratelimit(10, 60)
local event = Instance.new("RemoteEvent")
event.Parent = ReplicatedStorage

event.OnClientEvent:Connect(function(player, ...)
	if check_limit(player) then
		-- do stuff
	end
end)
```

## Constructor

Creates a new ratelimit object, with [`limit`](#limit) being the amount of times a key can be called every [`interval`](#interval) seconds.

> [!TIP]
> The limit is inclusive, use the maximum amount of calls you want to allow as the [`limit`](#limit).

```luau
local check_limit = ratelimit(10, 60)
```

## Methods

### `__call`

Checks if a given key's count has exceeded the [`limit`](#limit) within the current [`interval`](#interval)

> [!NOTE]
> The `key` arg isn't required, as ratelimit will use a default key instead

```luau
local check_limit = ratelimit(10, 60)
check_limit("meow")
```

## Properties

### `count_map`

A map with keys, with their values being the count for the specified key

```luau
type count_map<K> = { [K]: number }
```

### `limit`

The limit for the ratelimit object

```luau
type limit = number
```

### `interval`

The interval for the ratelimit object

```luau
type interval = number
```
