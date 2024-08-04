# Grouper

Module for getting accurate group ranks for players on the server, and detecting rank changes

```luau
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local grouper = require("grouper")

-- returning the team color, as setting Player.Team 
-- is less reliable than Player.TeamColor
local function CREATE_TEAM(name: string, color: BrickColor): BrickColor
	local team = Instance.new("Team")
	team.AutoAssignable = false
	team.Color = color
	team.Name = name
	team.Parent = Teams
	return color
end

local MIN_RANK_TO_TEAM = {
	[3] = CREATE_TEAM("Trainee", BrickColor.new("Violet")),
	[10] = CREATE_TEAM("Manager", BrickColor.new("Lilac")),
	[250] = CREATE_TEAM("Owners", BrickColor.new("Bright violet")),
}

local function SET_TEAM(player: Player, rank: number?)
	local rank = rank or grouper.rank(player)
	local prev_teamcolor: BrickColor

	for minrank, teamcolor in MIN_RANK_TO_TEAM do
		if rank >= minrank then
			prev_teamcolor = teamcolor
			continue
		end
		break
	end
	player.TeamColor = prev_teamcolor
end

grouper.init.server({ groupid = 31287129 })
Players.PlayerAdded:Connect(SET_TEAM)
grouper.on_rank_changed(SET_TEAM)
```

## Types

### `ClientConfig`

```luau
type ClientConfig = {
	connect_rank_changed: (
		callback: (player: Player, rank: number, role: string) -> ()
	) -> ()
}
```
* `connect_rank_changed` - a function that takes in a callback to run when the remote or other thingy used for networking fires to the client

### `ServerConfig`

```luau
type ServerConfig = {
	rank_refresh_rate: number?,
	fire_all_rank_changed: nil,
	fire_rank_changed: nil,
	groupid: number,
} |  {
	fire_rank_changed: (
		send_to_player: Player, player_whose_rank_changed: Player, 
		rank: number, role: string
	) -> (),
	fire_all_rank_changed: (
		player_whose_rank_changed: Player, rank: number, 
		role: string
	) -> (),
	rank_refresh_rate: number?,
	groupid: number,
}
```
* `fire_all_rank_changed` - callback for firing a rank change for a player to all players
* `fire_rank_changed` - callback for firing to a specific player a rank change, used for inital replication
* `rank_refresh_rate` - how often grouper should check each players rank in seconds (default: 30)
* `groupid` - the groupid for the group to track for each player if their rank changes within it

## Initalizers

### `server`

Initalizes grouper on the server, cannot be called from the client

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENT = Instance.new("RemoteEvent")
EVENT.Name = "GROUPER_EVENT"
EVENT.Parent = ReplicatedStorage

grouper.init.server({
	fire_all_rank_changed = function(...)
		EVENT:FireAllClients(...)
	end,
	fire_rank_changed = function(...)
		EVENT:FireClient(...)
	end,
	groupid = 33712377,
})
```

### `client`

Initalizes grouper on the client, cannot be called from the server

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENT: RemoteEvent = ReplicatedStorage:WaitForChild("GROUPER_EVENT") :: any

grouper.init.client({
	connect_rank_changed = function(callback)
		EVENT.OnClientEvent:Connect(callback)
	end,
})
```

## Methods

> [!TIP]
> Any methods that require getting the cached version of a players rank can yield. But will only yield when the player joins, or in studio for a short period of time. So treat these methods as synchronous, unless you're doing something thats not general usage

### `rank`

Gets a players current rank in the given group

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local rank = grouper.rank(player)

	if rank < 100 then
		player:Kick(`Ranks less than 100 cannot join\nYour rank: {rank}`)
	end	
end)
```

### `role`

Gets a players current role in the given group

```luau
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

Players.PlayerAdded:Connect(function(player)
	local role = grouper.role(player)
	local team = Teams:FindFirstChild(role)

	if not team then
		local new_team = Instance.new("Team")
		new_team.AutoAssignable = false
		new_team.Color = BrickColor.Random()
		new_team.Name = role
		new_team.Parent = Teams
		team = new_team :: any
	end

	player.TeamColor = team.Color
end)

```

### `is_in_group`

Returns a boolean indicating if a player is in the given group

```luau
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local TEAM_COLOR = BrickColor.new("Violet")
local GROUPIES_TEAM = Instance.new("Team")
GROUPIES_TEAM.AutoAssignable = false
GROUPIES_TEAM.Name = "Groupies :3"
GROUPIES_TEAM.Color = TEAM_COLOR
GROUPIES_TEAM.Parent = Teams

Players.PlayerAdded:Connect(function(player)
	if grouper.is_in_group(player) then
		player.TeamColor = TEAM_COLOR
	end
end)

```

### `rank_and_role`

Gets a players current rank and role

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local rank, role = grouper.rank_and_role(player)
	print(`{player.Name}'s rank and role is... {rank}, {role}`)
end)
```

### `on_rank_changed`

Attaches a callback to be called whenever a players rank changes in the server

```luau
grouper.on_rank_changed(function(player, new_rank, old_rank)
	if new_rank > 10 then
		print("meow!")
	else
		print("hissss")
		local character = player.Character

		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.Health = 0
		end
	end
end)
```

### `players`

Returns a dictionary where the keys are players, with the values being each players current rank. The returned dictionary does not auto-update, for that please use [`rank`](#rank)

```luau
local player_ranks = grouper.players()

for player, rank in player_ranks do
	if rank == 0 then
		player:Kick("Must be in group")
	end
end
```

### `roles`

Returns a dictionary where the keys are ranks, with the values being the corrosponding roles for each rank.
> [!NOTE]
> The returned dictionary may not include every role, as its filled as a player of every possible rank joins the server.

```luau
local roles = grouper.roles()

for rank, role in roles do
	print(`the role for rank {rank} is {role}`)
end

```
