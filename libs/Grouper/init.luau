--!optimize 2
--!native
--!strict

-- Grouper
-- Used for getting the latest group rank or role of a player on the server.
-- @kalrnlo
-- 23/04/2024

local group_service = game:GetService("GroupService")
local players = game:GetService("Players")

type RankChangedCallback = (player: Player, new_rank: number, old_rank: number) -> ()

-- {[user_id] = rank | treads_waiting_for_player_rank_to_be_fetched }
local player_ranks = {} :: { [number]: number | { thread } }
local role_cache = table.create(256, "Guest")
local rank_changed_callbacks = {} :: { { RankChangedCallback } }
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
		warn(`[GROUPER] Couldn't fetch rank for user {userid}\n\tgroup-service-err: {groups}`)
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
		local threads_waiting: {thread} = player_ranks[userid] :: {thread}
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

				for _, callback_data in rank_changed_callbacks do
					task.spawn(callback_data[1], player, new_rank, rank)
				end
				rank = new_rank
			end
			task.wait(rate)
		end
	else
		player_ranks[userid] = nil
	end
end

local function init(new_config: { rank_refresh_rate: number?, groupid: number })
	if has_initiated then return end
	new_config.rank_refresh_rate = new_config.rank_refresh_rate or config.rank_refresh_rate
	config = new_config :: typeof(config)
	has_initiated = true

	task.spawn(function()
		for _, player in players:GetPlayers() do
			task.spawn(on_player_added, player)
		end
	end)

	players.PlayerRemoving:Connect(on_player_removing)
	players.PlayerAdded:Connect(on_player_added)
end

local function on_rank_changed(callback: RankChangedCallback): () -> ()
	local data = table.create(1, callback)
	table.insert(rank_changed_callbacks, data)

	return function()
		local index: number = table.find(rank_changed_callbacks, data) :: any

		if index ~= 1 then
			local len = #rank_changed_callbacks
			rank_changed_callbacks[index] = rank_changed_callbacks[len]
			rank_changed_callbacks[len] = nil
		else
			rank_changed_callbacks[1] = nil
		end
	end
end

local function get_rank(player: Player): number
	local rank = player_ranks[player.UserId]

	if type(rank) == "number" then
		return rank
	elseif rank then
		table.insert(rank, coroutine.running())
		return coroutine.yield()
	elseif player and player:IsDescendantOf(players) then
		player_ranks[player.UserId] = { coroutine.running() }
		return coroutine.yield()
	else
		error "[GROUPER] Player has left game too early"
	end
end

local function get_rank_and_role(player: Player): (number, string)
	local rank = get_rank(player)
	return rank, role_cache[rank + 1]
end

local function is_in_group(player: Player): boolean
	return get_rank(player) ~= 0
end

local function get_role(player: Player): string
	return role_cache[get_rank(player) + 1]
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
