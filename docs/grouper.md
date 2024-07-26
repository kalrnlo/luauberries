# Grouper

A module for getting accurate group ranks for players on the server, and detecting rank changes

> [!WARNING]
> The docs for this library are outdated, but are mostly correct

```luau
local text_chat_service = game:GetService("TextChatService")
local players = game:GetService("Players")
local grouper = require("@kalrnlo/grouper")

local text_channels = text_chat_service:WaitForChild("TextChannels")
local general = text_channels:WaitForChild("RBXGeneral")

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

grouper.init.server({
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

> [!IMPORTANT]
> Every method except `init` and `on_rank_changed` can yield but only in select cases such as, if group service is being really slow, you're playtesting in studio, or init hasn't been called

```luau
get_rank_and_role(player)
```
Returns the current rank and role for the given player in the group.
- player: the player to get the rank and role of

```luau
on_rank_changed(callback)
```
Returns a disconnect function for the callback to be removed from the list of callbacks grouper will call when a players rank changes
- callback: a callback to be called each time a players rank changes with the following args, `player, new_rank, old_rank`

```luau
is_in_group(player)
```
Returns a boolean indicating if the given player is in the group.
- player: the player to check if they're in the group

```luau
get_rank(player)
```
Returns the given players current rank in the group
- player: the player to get the rank of

```luau
get_role(player)
```
Returns the given players current role in the group
- player: the player to get the role of

```luau
init(new_config)
```
Initates grouper starting rank tracking
- new_config: an optional config with the following optional fields, groupid, and rank_refresh_rate
