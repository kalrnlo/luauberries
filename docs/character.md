# Character

Utility for getting better types with player characters in roblox

```luau
local Players = game:GetService("Players")
local character = require("character")

Players.PlayerAdded:Connect(function(player)
	character.added(player, function(character)
		-- characters always have a primary part, so the character type includes 
		-- Model.PrimaryPart typed as BasePart and not BasePart?
		local rootpart = character.PrimaryPart
		-- doesn't produce a type error like it would with Player.CharacterAdded
		local humanoid = character.Humanoid

		humanoid.Died:Connect(function()
			print("oof")
		end)
	end)
end)
```

## Types

### `Character`

```luau
type Character = Model & {
    Humanoid: Humanoid & {
        HumanoidDescription: HumanoidDescription,
        Animator: Animator,
    },
    HumanoidRootPart: BasePart,
    BodyColors: BodyColors,
	PrimaryPart: BasePart,
    Animate: LocalScript,
    Head: BasePart,
}

```

* `HumanoidRootPart` - the [`PrimaryPart`](https://create.roblox.com/docs/reference/engine/classes/Model#PrimaryPart) of the character
* `Animate` - the [`LocalScript`](https://create.roblox.com/docs/reference/engine/classes/LocalScript) that handles playing character animations such as walking, emotes, ect
* `Head` - the [`BasePart`](https://create.roblox.com/docs/reference/engine/classes/BasePart) that is the characters head
* [`PrimaryPart`](https://create.roblox.com/docs/reference/engine/classes/Model#PrimaryPart)
* [`BodyColors`](https://create.roblox.com/docs/reference/engine/classes/BodyColors)
* [`Humanoid`](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
	* [`HumanoidDescription`](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription)
	* [`Animator`](https://create.roblox.com/docs/reference/engine/classes/Animator)

## Methods

### `added`

Wrapper around [`Player.CharacterAdded`](https://create.roblox.com/docs/reference/engine/classes/Player#CharacterAdded), except that if the given `Player` already has a character it'll run the given callback for the existing character. Unless the third arg `dont_run_for_existing_character` is true

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local disconnect = character.added(player, function(character)
		character.Humanoid.DisplayName = "🐈"
	end)

	task.wait()
	disconnect()
end)
```

### `added_once`

Same as [`added`](#added), except that it only runs the callback once and not for every character added
afterwards.

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local disconnect = character.added_once(player, function(character)
		character.Humanoid.DisplayName = `{character.Name}'s first character!`
	end)
end)
```

### `removing`

Wrapper around [`Player.CharacterRemoving`](https://create.roblox.com/docs/reference/engine/classes/Player#CharacterRemoving) but with the character being typed as the [`character`](#character-1) type instead of just [`Model`](https://create.roblox.com/docs/reference/engine/classes/Player#Character)

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local disconnect

	disconnect = character.removing(player, function(character)
		print("died")
		disconnect()
	end)
end)
```

### `removing_once`

Same as [`removing`](#removing), except that it only runs the callback once and not for every character added
afterwards.


```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	character.removing(player, function(character)
		print(`{character.Name}'s first death!`)
	end)
end)
```

### `get`

Wrapper function for [`Player.Character`](https://create.roblox.com/docs/reference/engine/classes/Player#Character) so you don't have to typecast [`Player.Character`](https://create.roblox.com/docs/reference/engine/classes/Player#Character) as the [`Character`](#character-1) type

```luau
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = character.get(player)
```