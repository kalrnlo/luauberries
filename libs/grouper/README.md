### Grouper

A module for getting accurate group ranks for players on the server, and detecting rank changes

#### example
```lua
local text_chat_service = game:GetService("TextChatService")
local players = game:GetService("Players")
local grouper = require("@kalrnlo/Grouper")

local text_channels = text_chat_service:WaitForChild("TextChannels")
local general = text_chat_service:WaitForChild("RBXGeneral")

local function create_text_channel(name: string)
	local channel = Instance.new("TextChannel")
	channel.Name = name
	channel.Parent = text_channels
	return channel
end

local group_channels = {
	[2] = create_text_channel("trainee"),
	[4] = create_text_channel("barista"),
}

grouper.init({
	-- how often in seconds grouper should check to see if a players rank has changed
	rank_refresh_rate = 60,
	-- the groupid for the group grouper checks ranks for
	groupid = 31287129,
})

-- Using child added on the general channel, as every player that can chat
-- is added to the general channel, and trying to add a player to a text channel
-- right when they join with PlayerAdded is going to fail as chat hasn't loaded
-- for that player yet so were doing this jank thing
general.ChildAdded:Connect(function(source: TextSource)
	local player: Player? = players:FindFirstChild(source.Name) :: any

	if player then
		local rank = grouper.get_rank(player)

		for minrank, channel in group_channels do
			if rank >= minrank then
				channel:AddUserAsync(player.UserId)
			end
		end
	end
end)

grouper.on_rank_changed(function(player, new_rank)
	for minrank, channel in group_channels do
		if new_rank >= minrank then
			channel:AddUserAsync(player.UserId)
		else
			local source = channel:FindFirstChild(player.Name)

			if source then
				source:Destroy()
			end
		end
	end
end)
```

### api
#### methods
###   
> [!NOTE]
> Every method except init can yield but only in select cases
> - if group service is being really slow for some weird reason
> - you're playtesting in studio
> - init hasn't been called

###   
```lua
grouper.get_rank_and_role(player)
```
Returns the current rank and role for the given player in the group.
- player: the player to get the rank and role of
###   
```lua
grouper.is_in_group(player)
```
Returns a boolean indicating if the given player is in the group.
- player: the player to check if they're in the group
###   
```lua
grouper.get_rank(player)
```
Returns the given players current rank in the group
- player: the player to get the rank of
###   
```lua
grouper.get_role(player)
```
Returns the given players current role in the group
- player: the player to get the role of
###   
```lua
grouper.init(new_config)
```
Initates grouper starting rank tracking
- new_config: an optional config with the following optional fields, groupid, and rank_refresh_rate
###   
#### properties
###   
```lua
grouper.config
```
The current config grouper is using