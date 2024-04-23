--!optimize 2
--!native
--!strict

-- 🐟 Grouper
-- Used for getting the latest group rank or role of a player on the server.
-- @kalrnlo
-- 22/04/2024

local group_service = game:GetService("GroupService")
local players = game:GetService("Players")
local config_merge = require("@kalrnlo/ConfigMerge")

type CallbackClass = typeof(setmetatable({} :: { RankChangedCallback }, {} :: CallbackPrototype))
type RankChangedCallback = (player: Player, new_rank: number, old_rank: number) -> ()
type CallbackPrototype = { __call: (self: CallbackClass) -> () }

-- {[user_id] = rank | treads_waiting_for_player_rank_to_be_fetched }
local player_ranks = {} :: { [number]: number | { thread } }
local rank_changed_callbacks = {} :: { CallbackClass }
local role_cache = table.create(256, "Guest")
local has_initiated = false
local config = {
	rank_refresh_rate = 30,
	groupid = 0,
}

local function FETCH_RANK(userid: number, groupid: number): number?
	local success, groups = pcall(group_service.GetGroupsAsync, group_service, userid)
	
	if success then
		for _, group in groups do
			if group.Id ~= groupid then continue end
			role_cache[group.Rank + 1] = group.Role
			return group.Rank
		end
	else
		warn `[GROUPER] Couldn't fetch rank for user {userid}\n\tgroup-service-err: {groups}`
	end
	
	return nil
end

local function on_player_removing(player: Player)
	player_ranks[player.UserId] = nil
end

local function on_player_added(player: Player)
	local rate = config.rank_refresh_rate
	local groupid = config.groupid
	local userid = player.UserId
	local start = time()
	local rank = FETCH_RANK(userid, groupid) or 0

	if player and player:IsDescendantOf(players) then
		local threads_waiting = player_ranks[userid]
		player_ranks[userid] = rank
	
		if threads_waiting then
			for _, thread in threads_waiting do
				task.spawn(thread, rank)
			end
		end

		local time_diff = time() - start
		if time_diff < rate then
			task.wait(rate - time_diff)
		end

		while player_ranks[userid] do
			local new_rank = FETCH_RANK(userid, groupid)

			if not player_ranks[userid] then
				return
			elseif new_rank and new_rank ~= rank then
				player_ranks[userid] = new_rank

				for _, callback in rank_changed_callbacks do
					task.spawn(callback[1], player, new_rank, rank)
				end
				rank = new_rank
			end
			task.wait(rate)
		end
	else
		player_ranks[user_id] = nil
	end
end

local function callback_call(self: CallbackClass)
	if #rank_changed_callbacks > 1 then
		local index = table.find(rank_changed_callbacks, self) :: number
		rank_changed_callbacks[index] = rank_changed_callbacks[#rank_changed_callbacks]
		rank_changed_callbacks[#rank_changed_callbacks] = nil
	else
		rank_changed_callbacks[1] = nil
	end
end

local callback_prototype = {
	__call = callback_call
}
callback_prototype.__index = callback_prototype
table.freeze(callback_prototype)

local function init(new_config: { rank_refresh_rate: number?, groupid: number? }?)
	if has_initiated then return end
	has_initiated = true

	config_merge(config, new_config)
	task.spawn(function()
		for _, player in players:GetPlayers() do
			task.spawn(on_player_added, player)
		end
	end)

	players.PlayerRemoving:Connect(on_player_removing)
	players.PlayerAdded:Connect(on_player_added)
end

local function on_rank_changed(callback: RankChangedCallback): () -> ()
	local callback_data = setmetatable(table.create(1, Callback), callback_prototype) :: any
	table.insert(rank_changed_callbacks, callback_data)
	return callback_data
end

local function get_rank(player: Player): number
	local userid = player.UserId
	local rank = player_ranks[userid]

	if type(rank) == "number" then
		return rank
	elseif rank then
		table.insert(rank, coroutine.running())
		return coroutine.yield()
	elseif player and player:IsDescendantOf(players) then
		player_ranks[userid] = { coroutine.running() }
		return coroutine.yield()
	else
		error "[GROUPER] Player has left game too early"
	end
end

local function get_rank_and_role(player: Player)
	local rank = get_rank(player)
	return rank, role_cache[rank + 1]
end

local function is_in_group(player: Player)
	return get_rank(player) ~= 0
end

local function get_role(player: Player)
	return role_cache[get_rank(Player) + 1]
end

local exports = table.freeze {
	get_rank_and_role = get_rank_and_role,
	on_rank_changed = on_rank_changed,
	config = config :: typeof(config),
	is_in_group = is_in_group,
	get_rank = get_rank,
	get_role = get_role,
	init = init,
}

return exports
