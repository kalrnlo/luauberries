# Safe Teleport

[`TeleportService:TeleportAsync`](https://create.roblox.com/docs/reference/engine/classes/TeleportService#TeleportAsync) wrapper that makes teleporting simple

```luau
local Players = game:GetService("Players")
local safeteleport = require("safeteleport")

safeteleport(102091321, Players:GetPlayers(), {
    data = {
        soft_shutdown = true,
    },
    reserve_server = true,
})

```

## Types

### `SafeTeleportInfo`

```luau
type SafeTeleportInfo = {
    reserve_server: boolean?,
    data: { [string]: any }?,
    access_code: string?,
    jobid: string?,
}
```
* `reserve_server` - indicates if a server should be reserved for this teleport
* `data` - the teleport data to send with the teleport
* `access_code` - a reserved server access code for teleporting to a specific reserved server
* `jobid` - the [`JobId`](https://create.roblox.com/docs/reference/engine/classes/DataModel#JobId) of the server to teleport to

### `SafeTeleportResult`

```luau
type SafeTeleportResult = {
    private_server_id: string,
    access_code: string,
}
```
* `private_server_id` - the [`PrivateServerId`](https://create.roblox.com/docs/reference/engine/classes/DataModel#PrivateServerId) of the server that the players were teleported to
* `access_code` - the reserved server access code for server the players were teleported to


## Methods

### `__call`

Safely teleports a player or an array of players to another place, or server. Accepts a third optional arg called `info` for passing a [`SafeTeleportInfo`](#safeteleportinfo).

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local success, result = safeteleport(102091321, player)

	if not success then
		player:Kick("teleport failed!")
	end
end)
```

## Properties

> [!WARNING]
> Properties cannot be edited after the first time the [`__call`](#call) method is invoked,
> as the safe teleport table is frozen when [`__call`](#call) is invoked.

### `ATTEMPT_LIMIT`

How many times should safe teleport retry a teleport before giving up (default: 5)

```luau
type ATTEMPT_LIMIT = number
```

### `RETRY_DELAY`

An amount of seconds between retrying a teleport if it has failed (default: 1)

```luau
type RETRY_DELAY = number
```

### `FLOOD_DELAY`

An amount of seconds between retrying a teleport if [`TeleportService`](https://create.roblox.com/docs/reference/engine/classes/TeleportService) is flooded (default: 5)

```luau
type ATTEMPT_LIMIT = number
```
