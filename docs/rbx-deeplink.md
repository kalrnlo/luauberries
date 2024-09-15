# Rbx Deeplink

Small utility with basic functions for dealing with [roblox deeplinks](https://create.roblox.com/docs/reference/engine/classes/Player#GetJoinData)

```luau
local Players = game:GetService("Players")
local safeteleport = require("@safeteleport")
local rbx_deeplink = require("@rbx_deeplink")

local PLACEID = game.PlaceId

Players.PlayerAdded:Connect(function(player)
	local jobid = rbx_deeplink.launchdata(player)

	if jobid then
		safeteleport(PLACEID, player, {
			jobid = jobid
		})
	end
end)

```

## Methods

### `get_launchdata`

Gets the launchdata for the given player (the actual launchdata not the full join url that [`Player:GetJoinData().LaunchData`](https://create.roblox.com/docs/reference/engine/classes/Player#GetJoinData) gives), and [decodes](url.md#decode) it

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local launchdata = url.get_launchdata(player)

	if launchdata then
		print(`{player.Name}'s launchdata: {launchdata}`)
	end
end)
```

### `format`

Format is ideal if you don't want to setup a redirect domain because appsflyer urls look very sketch. Although please note urls created with format will not redirect the user to install roblox, like [`format_appsflyer`](#format_appsflyer) will.

```luau
print(rbxdeeplink.format(0, meow)) -- https://www.roblox.com/games/start?placeId=0&launchData=meow
```

### `format_appsflyer`

Same as [`format`](#format), except it formats the url in the apps flyer format, apps flyer urls are preferred because if the user doesn't have roblox installed the url will instead redirect the user to the app store. Or to install roblox on the website.

```luau
--[[
	https://ro.blox.com/Ebh5?af_dp=https%3A%2F%2Fwww.roblox.com%2Fgames%2Fstart%3FplaceId%3D0%26launchData%3Dmeow&af_web_dp=https%3A%2F%2Fwww.roblox.com%2Fgames%2Fstart%3FplaceId%3D0%26launchData%3Dmeow
--]]
print(rbxdeeplink.format_appsflyer(0, "meow"))
```