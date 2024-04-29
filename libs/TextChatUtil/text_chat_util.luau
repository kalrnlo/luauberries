--!strict

-- TextChatUtil
-- simple utility module for TextChatService
-- @Kalrnlo
-- 25/04/2024

local text_chat_service = game:GetService("TextChatService")
local players = game:GetService("Players")

local players_chat_loaded = {} :: { [number]: { thread } | true }
local player_sources = {} :: { [number]: { TextSource } }
 -- chat verified icon unicode
local verified_char = utf8.char(0xE000)
local defualt_message_prefix = ":  "
local chat_name_colors = {
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
local color_amount = #chat_name_colors

local function on_descendant_added(descendant: Instance)
	if descendant:IsA("TextSource") then
		local threads_waiting = players_chat_loaded[descendant.UserId]
		local sources = player_sources[descendant.UserId]

		if type(threads_waiting) == "table" then
			players_chat_loaded[descendant.UserId] = true
			for _, thread in threads_waiting do
				task.spawn(thread, true)
			end
		end

		if sources then
			table.insert(sources, descendant)
		else
			player_sources[descendant.UserId] = { descendant }
		end
	end
end

local function on_descendant_removed(descendant: Instance)
	if descendant:IsA("TextSource") then
		local sources = player_sources[descendant.UserId]

		if sources then
			local index = table.find(sources, descendant)

			if index then
				table.remove(sources, index)
			end
		end
	end
end

task.spawn(function()
	text_chat_service.DescendantRemoving:Connect(on_descendant_removed)
	players.PlayerRemoving:Connect(function(player)
		players_chat_loaded[player.UserId] = nil
		player_sources[player.UserId] = nil
	end)
	task.spawn(function()
		for _, descendant in text_chat_service:GetDescendants() do
			on_descendant_added(descendant)
		end
	end)

	text_chat_service.DescendantAdded:Connect(on_descendant_added)
end)

local function wait_for_player_chat_loaded(player: Player)
	if text_chat_service:CanUserChatAsync(player.UserId) then
		local has_player_loaded = players_chat_loaded[player.UserId]
	
		if has_player_loaded == true then
			return true
		elseif has_player_loaded then
			table.insert(has_player_loaded, coroutine.running())
			return coroutine.yield()
		elseif player and player:IsDescendantOf(players) then
			players_chat_loaded[player.UserId] = { coroutine.running() }
			return coroutine.yield()
		end
	end

	return false
end

local function add_player_to_channel(player: Player, channel: TextChannel): ((true, TextSource) | (false, nil))
	if wait_for_player_chat_loaded() then
		local source, success = channel:AddUserAsync(player.UserId)
		return success, source
	else
		return false, nil
	end
end

local function remove_player_from_channel(player: Player, channel: TextChannel)
	if wait_for_player_chat_loaded() then
		local source = channel:FindFirstChild(player.Name)

		if source then
			source:Destroy()
		end
	end
end

local function get_color_for_name(name: string)
	local sub_number = if #name % 2 == 1 then -1 else 0
	local name_value = 0
	
	for index, codepoint in utf8.codes(name) do
		name_value += if (((#name - index) + 1) - sub_number) % 4 >= 2 then
				-codepoint
			else
				codepoint
	end
	
	return chat_name_colors[(name_value % color_amount) + 1]
end

local function set_player_mute(player: Player, ismuted: boolean, channel: TextChannel?)
	if wait_for_player_chat_loaded() then
		local sources = player_sources[player.UserId]

		if channel then
			for _, source in sources do
				if source:IsDescendantOf(channel) then
					source.IsMuted = ismuted
					return
				end
			end
		else
			for _, source in sources do
				source.IsMuted = ismuted
			end
		end
	end
end

local function is_player_muted(player: Player, channel: TextChannel?)
	if wait_for_player_chat_loaded() then
		local sources = player_sources[player.UserId]

		if channel then
			for _, source in sources do
				if source:IsDescendantOf(channel) then
					return source.IsMuted
				end
			end

			return false
		else
			local muted_count = 0

			for _, source in sources do
				if source.IsMuted then
					muted_count += 1
				end
			end

			return #sources == muted_count
		end
	end
end

local function get_chat_prefix(
	display: string,
	name: string,
	is_verified: boolean?,
	include_name: boolean?,
	prefix: string?
)
	local displayed_name = if include_name then `{display}(@{name})` else display
	local color_hex = get_color_for_name(name):ToHex()
	local prefix = prefix or defualt_message_prefix

	if is_verified then
		return `<font color="#{color_hex}">{verified_char}{displayed_name}</font>{prefix}`
	else
		return `<font color="#{color_hex}">{displayed_name}</font>{prefix}`
	end
end

local function get_chat_prefix_for_player(player: Player, include_name: boolean?, prefix: string?)
	return get_chat_prefix(
		player.DisplayName,
		player.Name,
		player.HasVerifiedBadge,
		include_name,
		prefix
	)
end

local function get_color_for_player(player: Player)
	return get_color_for_name(player.Name)
end

local exports = table.freeze {
	channel = table.freeze {
		remove = remove_player_from_channel,
		add = add_player_to_channel,
	},
	prefix = table.freeze {
		player = get_chat_prefix_for_player,
		create = get_chat_prefix,
	},
	color = table.freeze {
		player = get_color_for_player,
		name = get_color_for_name,
	},
	mute = table.freeze {
		set = set_player_mute,
		is = is_player_muted,
	},
}

return exports