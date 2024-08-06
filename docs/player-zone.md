# Player Zone

Fast module for detecting players in rectangular zones

```luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local playerzone = require("playerzone")
local character = require("character")

local TEAM_TO_CONNECTIONS = { [Team]: { RBXScriptConnection } }
local TEAM_TO_ZONES = { [Team]: { playerzone.WhitelistZone } }

local function ZONE_CALLER(
	zones: { playerzone.WhitelistZone },
	callback: (zone: playerzone.WhitelistZone, player: Player) -> ()
): (player: Player) -> ()
	return function(player: Player)
		for _, zone in zones do
			callback(zone, player)
		end
	end
end

local function on_team_added(team: Team)
	local color = team.Color
	local zones = {}

	for _, zonepart in CollectionService:GetTagged("TEAM_ZONE") do
		if color == zonepart:GetAttribute("TeamColor") then
			table.insert(zones, playerzone.create({
				callback = function(character)
					character.Humanoid.Health = 0
				end,
				cframe = zonepart.CFrame,
				size = zonepart.Size,
				type = "WHITELIST",
			}))
		end
	end

	for _, player in team:GetPlayers() do
		add_to_whitelist(player)
	end

	TEAM_TO_CONNECTIONS[team] = {
		team.PlayerRemoving:Connect(ZONE_CALLER(zones, playerzone.remove)),
		team.PlayerAdded:Connect(ZONE_CALLER(zones, playerzone.insert)),
	}
	TEAM_TO_ZONES[team] = zones
end

local function CLEAN_TBL<V>(t: { V }?, cleaner: (self: V) -> ())
	if t then
		for _, value in t do
			cleaner(value)
		end
	end
end

local connection = Teams.ChildAdded:Connect(on_team_added)
local rbx_disconnect = connection.Disconnect

Teams.ChildRemoving:Connect(function(team: Team)
	local connections = TEAM_TO_CONNECTIONS[team]
	local zones = TEAM_TO_ZONES[team]

	CLEAN_TBL(TEAM_TO_CONNECTIONS[team], rbx_disconnect)
	CLEAN_TBL(TEAM_TO_ZONES[team], playerzone.destroy)
	TEAM_TO_CONNECTIONS[team] = nil
	TEAM_TO_ZONES[team] = nil
end :: any)

for _, team in Teams:GetTeams() do
	if not TEAM_TO_ZONES[team] then
		on_team_added(team)
	end
end
```

## Types

> [!NOTE]
> `character.Character` is a reference to the [`Character`](https://libs.luau.lol/character#character-1) type in the character library


### `ZoneType`

```luau
type ZoneType = "WHITELIST" | "BLACKLIST"
```

### `PlayerZoneInfo`

> [!WARNING]
> This type isn't exported, its just documented because of [`BaseZone`](#basezone) referencing it.

```luau
type PlayerZoneInfo = {
	character: character.Character,
	rootpart: BasePart,
	position: Vector3,
	player: Player,
}
```
* `character` - a reference to the current character of the player
* `rootpart` - a refrerence to the PrimaryPart of the character
* `position` - the current position of the players character
* `player` - a reference to the [`Player`]() this [`PlayerZoneInfo`](#playerzoneinfo) is for

### `BaseZone`

```luau
type BaseZone<Type = ZoneType> = {
	callback: (character: character.Character, player: Player) -> (),
	blacklist: { PlayerZoneInfo },
	size_halved_x: number,
	size_halved_y: number,
	size_halved_z: number,
	cframe: CFrame,
	size: Vector3,
	id: number,
	type: Type,
}
```
* `callback` - the callback to be called when a player thats not allowed in the zone is found in the zone
* `blacklist` - an array of [`PlayerZoneInfos`](#playerzoneinfo) for every player thats not allowed in the zone
* `id` - a unique identifying number for the zone, intended to be used for replication
* `size_halved_x` - the x axis of the zones size halved
* `size_halved_x` - the y axis of the zones size halved
* `size_halved_z` - the z axis of the zones size halved
* `type` - the [`ZoneType`](#zonetype) for the zone
* `cframe` - the [`CFrame`](https://create.roblox.com/docs/reference/engine/datatypes/CFrame) of the zone
* `size` - the size of the zone

### `WhitelistZone`

```luau
type WhitelistZone = BaseZone<"WHITELIST"> & {
	whitelisted: { Player },
}
```
* `whitelisted` - an array of players that are allowed to be in the zone

### `BlacklistZone`

```luau
type BlacklistZone = BaseZone<"BLACKLIST"> & {
	blacklisted: { Player },
}
```
* `blacklisted` - an array of players that are not allowed to be in the zone

### `Zone`

```luau
type Zone = BlacklistZone | WhitelistZone
```

### `ZoneInfo`

```luau
type ZoneInfo<Type = ZoneType> = {
	callback: (character: character.Character, player: Player) -> (),
	cframe: CFrame,
	size: Vector3,
	type: Type?,
}
```
* `callback` - the callback to be ran when a player thats not allowed to be in the given zone is in the zone
* `cframe` - the [`CFrame`](https://create.roblox.com/docs/reference/engine/datatypes/CFrame) for the zone
* `size` - the size of the zone
* `type` - the type of zone this is (default: "BLACKLIST")

## Methods

### `create`

Creates a new player zone from the provided [`ZoneInfo`](#zoneinfo)

```luau
local zone = playerzone.create({
	cframe = CFrame.new(12.4, 50, 2),
	size = Vector3.new(10, 20, 10),
	type = "WHITELIST"
})
```

### `destroy`

Destroys a player zone allowing it to be gc'd

```luau
local zone = playerzone.create({
	cframe = CFrame.new(12.4, 50, 2),
	size = Vector3.new(10, 20, 10),
})

playerzone.destroy(zone)
```

### `insert`

Inserts a player to the whitelist or blacklist depending on the [`ZoneType`](#zonetype) of the player zone

```luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local zone = playerzone.create({
	cframe = CFrame.new(12.4, 50, 2),
	size = Vector3.new(10, 20, 10),
})

CollectionService:GetInstanceRemovingSignal("ALLLOWED"):Connect(function(player: Player)
	playerzone.insert(zone, player)
end :: any)
```

### `remove`

Removes a player from the whitelist or blacklist depending on the [`ZoneType`](#zonetype) of the player zone

```luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local zone = playerzone.create({
	cframe = CFrame.new(12.4, 50, 2),
	size = Vector3.new(10, 20, 10),
})

CollectionService:GetInstanceRemovingSignal("ALLLOWED"):Connect(function(player: Player)
	playerzone.remove(zone, player)
end :: any)

```
