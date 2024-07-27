# Ratelimit

Object for handling ratelimits intuitively, can be used without a Ratelimits many keys in a very intuitive interface. Ratelimits can also be used without any keys

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

## Type

```luau
type Ratelimit<K> = {
	@metatable { 
		__call: (self: Ratelimit<K>, key: K?) -> boolean 
	}

	count_map: { [K]: number },
	interval: number,
	limit: number,
	count: number,
}
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

Checks if a given key's count or [`count`](#count) has exceeded the [`limit`](#limit) within the current [`interval`](#interval)

```luau
local check_limit = ratelimit(10, 60)
check_limit("meow")
```

## Properties

### `count`

The count for when the ratelimit object has its [`__call`](#__call) metamethod invoked without the key argument 

```luau
type count = number
```

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