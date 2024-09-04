# Observer

Simple observer library for roblox

```luau
local observer = require("observer")

local disconnect = observer.character(function(character, player)
    character:SetAttribute("rank", player:GetRankInGroup(23239231))

    return function()
        character:SetAttribute("rank", nil)
    end
end)

task.wait(60)

disconnect()

```

#### methods

```luau
localtool(tag, callback, dont_add_existing)
```
- `tag` - the tag a tool should have to be observed
- `callback`- a function to be used to observe a tool, that optionally returns a function to be called when the tool is unequipped
- `dont_add_existing` - a boolean that if true, the observer will not observe already equipped tools with the given tag

```luau
character(callback, dont_add_existing)
```
- `callback` - a function to be used to observe a character and a player, that optionally returns a function thats called when a character is destroyed
- `dont_add_existing` - a boolean that if true, the observer will not observe already existing character and player pairs

```luau
tool(tag, callback, dont_add_existing)
```
- `tag`- the tag a tool should have to be observed
- `callback` - a function to be used to observe a tool, that optionally returns a function to be called when that tool is unequipped 
- `dont_add_existing` - a boolean that if true, the observer will not observe already equipped tools with the given tag

```luau
tag(tag, callback, dont_add_existing)
```
- `tag` - the tag a instance should have to be observed
- `callback` - a function to be used to observe a instance, that optionally returns a function to be called when that instance is destroyed
- `dont_add_existing` - a boolean that if true will not observe already existing instances with the given tag

```luau
player(callback, dont_add_existing)
```
- `callback` - a function to be used to observe a player, that optionally returns a function to be called when the player leaves the game
- `dont_add_existing` - a boolean that if true, the observer will not observe already existing players
