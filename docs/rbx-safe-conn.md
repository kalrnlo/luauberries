# Rbx Safe Conn

Connects to events where you'd want to probably also iterate over an array and call the same callback on every array item

```luau
local rbxsafeconn = require("rbxsafeconn")

rbxsafeconn.player_added(function(player)
	local character = player.Character

	if character then
		character.Humanoid.Health = 0
	end
end)
```

## Methods

### `player_added`

Connects a callback to [`Players.PlayerAdded`](https://create.roblox.com/docs/reference/engine/classes/Players#PlayerAdded), and runs the callback for every player already in-game

```luau
rbxsafeconn.player_added(function(player)
	if player:GetRankInGroup(103299423) >= 30 then
		player:AddTag("GROUP MEMBER")
	end
end)
```

### `tag_added`

Connects a callback to the instance added signal for the given tag, and runs the callback for every instance already existing with that tag

```luau
rbxsafeconn.tag_added("GROUP MEMBER", function(player: Player)
	print(`{player.Name} is a group member!`)
end)
```
