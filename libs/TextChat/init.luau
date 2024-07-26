
-- textchat
-- simple utility module for TextChatService

local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local VERIFIED_CHAT_PREFIX_FORMAT = "<font color=\"#%*\">\u{E000}%*</font>%*`"
local CHAT_PREFIX_FORMAT = "<font color=\"#%*\">%*</font>%*`"
local PLAYERS_CHAT_LOADED = {} :: { [number]: { thread } | true }
local PLAYER_SOURCES = {} :: { [number]: { TextSource } }
local DEFUALT_CHAT_PREFIX = ":  "
local CHAT_COLORS = table.freeze {
	 -- BrickColor.new("Bright red").Color,
	Color3.new(253/255, 41/255, 67/255),
	 -- BrickColor.new("Bright blue").Color,
	Color3.new(1/255, 162/255, 255/255),
	 -- BrickColor.new("Earth green").Color,
	Color3.new(2/255, 184/255, 87/255),
	BrickColor.new("Bright violet").Color,
	BrickColor.new("Bright orange").Color,
	BrickColor.new("Bright yellow").Color,
	BrickColor.new("Light reddish violet").Color,
	BrickColor.new("Brick yellow").Color,
}
local COLOR_COUNT = #CHAT_COLORS

local function on_descendant_added(descendant: Instance)
	if descendant:IsA("TextSource") then
		local sources = PLAYER_SOURCES[descendant.UserId]

		if sources then
			table.insert(sources, descendant)
		else
			PLAYER_SOURCES[descendant.UserId] = { descendant }
		end
	end
end

local function on_descendant_removed(descendant: Instance)
	if descendant:IsA("TextSource") then
		local sources = PLAYER_SOURCES[descendant.UserId]

		if sources then
			local index = table.find(sources, descendant)

			if index then
				table.remove(sources, index)
			end
		end
	end
end

local function wait_for_player_chat_loaded(player: Player): boolean
	if TextChatService:CanUserChatAsync(player.UserId) then
		local has_player_loaded: true | {thread} = PLAYERS_CHAT_LOADED[player.UserId]
	
		if has_player_loaded == true then
			return true
		elseif has_player_loaded then
			table.insert(has_player_loaded, coroutine.running())
			return coroutine.yield()
		elseif player and player:IsDescendantOf(Players) then
			PLAYERS_CHAT_LOADED[player.UserId] = { coroutine.running() }
			return coroutine.yield()
		end
	end

	return false
end

local function add_player_to_channel(player: Player, channel: TextChannel): (boolean, TextSource)
	if wait_for_player_chat_loaded(player) then
		-- doing this because otherwise i get a type error, even tho this is like the actual type for it according to docs
		local add_user_async = channel.AddUserAsync :: (self: TextChannel, user: number) -> (TextSource, boolean)
		local source, success = add_user_async(channel, player.UserId)
		return success, source
	else
		return false, nil :: any
	end
end

local function remove_player_from_channel(player: Player, channel: TextChannel)
	if wait_for_player_chat_loaded(player) then
		local source = channel:FindFirstChild(player.Name)

		if source then
			source:Destroy()
		end
	end
end

local function get_color_for_name(name: string): Color3
	local name_len = #name
	local sub_number = if name_len % 2 == 1 then -1 else 0
	local name_value = 0
	
	for index, codepoint in { string.byte(name, 1, name_len) } do
		name_value += if (((name_len - index) + 1) - sub_number) % 4 >= 2 then
				-codepoint
			else
				codepoint
	end
	
	return CHAT_COLORS[(name_value % COLOR_COUNT) + 1]
end

local function set_player_mute(player: Player, ismuted: boolean, channel: TextChannel?)
	if wait_for_player_chat_loaded(player) then
		if channel then
			local source = channel:FindFirstChild(player.Name)

			if source then
				(source :: any).IsMuted = ismuted
			end
		else
			for _, source: any in PLAYER_SOURCES[player.UserId] do
				source.IsMuted = ismuted
			end
		end
	end
end

local function is_player_muted(player: Player, channel: TextChannel?): boolean
	if wait_for_player_chat_loaded(player) then
		if channel then
			local source = channel:FindFirstChild(player.Name)

			return if source then (source :: any).IsMuted else false
		else
			local sources = PLAYER_SOURCES[player.UserId]
			local muted_count = 0

			for _, source: any in sources do
				if source.IsMuted then
					muted_count += 1
				end
			end

			return #sources == muted_count
		end
	else
		return false
	end
end

local function get_chat_prefix(
	display: string,
	name: string,
	is_verified: boolean?,
	include_name: boolean?,
	prefix: string?
): string
	return string.format(
		if is_verified then VERIFIED_CHAT_PREFIX_FORMAT else CHAT_PREFIX_FORMAT, 
		get_color_for_name(name):ToHex(),
		if include_name then `{display}(@{name})` else display,
		prefix or DEFUALT_CHAT_PREFIX
	)
end

local function get_chat_prefix_for_player(player: Player, include_name: boolean?, prefix: string?): string
	return get_chat_prefix(
		player.DisplayName,
		player.Name,
		player.HasVerifiedBadge,
		include_name,
		prefix
	)
end

local function get_color_for_player(player: Player): Color3
	return get_color_for_name(player.Name)
end

if RunService:IsServer() then

	TextChatService.DescendantRemoving:Connect(on_descendant_removed)
	TextChatService.DescendantAdded:Connect(on_descendant_added)
	Players.PlayerRemoving:Connect(function(player)
		PLAYERS_CHAT_LOADED[player.UserId] = nil
		PLAYER_SOURCES[player.UserId] = nil
	end)
	task.spawn(function()
		for _, descendant in TextChatService:GetDescendants() do
			on_descendant_added(descendant)
		end
	end)

	RunService.PostSimulation:Connect(function()
		for userid in PLAYER_SOURCES do
			local waiting_threads = PLAYERS_CHAT_LOADED[userid]

			if type(waiting_threads) == "table" then
				PLAYERS_CHAT_LOADED[userid] = true

				for _, thread in waiting_threads do
					task.spawn(thread, true)
				end
			end
		end
	end)
	
end

return table.freeze({
	get_prefix_for_player = get_chat_prefix_for_player,
	remove_from_channel = remove_player_from_channel,
	get_color_for_player = get_color_for_player,
	add_to_channel = add_player_to_channel,
	get_color = get_color_for_name,
	get_prefix = get_chat_prefix,
	set_mute = set_player_mute,
	is_muted = is_player_muted,
})