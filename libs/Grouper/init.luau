--!optimize 2
--!native
--!strict

-- Grouper
-- Used for getting the latest group rank or role of a player on the server.
-- @kalrnlo
-- 25/04/2024

local GROUP_SERVICE = game:GetService("GroupService")
local PLAYERS = game:GetService("Players")

type RankChangedCallback = (player: Player, new_rank: number, old_rank: number) -> ()

local THREADS_WAITING_FOR_PLAYERS = {} :: { [Player]: { thread } }
local RANK_CHANGED_CALLBACKS = {} :: { { RankChangedCallback } }
local GET_GROUPS_ASYNC = GROUP_SERVICE.GetGroupsAsync
local PLAYER_RANKS = {} :: { [Player]: number }
local ROLE_CACHE = table.create(256, "Guest")
local INITIATED = false
local CONFIG = {
	rank_refresh_rate = 30,
	groupid = 0,
}

local function FETCH_RANK(userid: number, groupid: number): number?
	local success, groups = pcall(GET_GROUPS_ASYNC, GROUP_SERVICE, userid)
	
	if success then
		for _, group in groups do
			if group.Id ~= groupid then continue end
			local rank = group.Rank
			ROLE_CACHE[rank + 1] = group.Role
			return rank
		end
	else
		warn(`[GROUPER] Couldn't fetch rank for user {userid}\n\tgroup-service-err: {groups}`)
	end
	
	return nil
end

local function on_player_removing(player: Player)
	PLAYER_RANKS[player] = nil
end

local function on_player_added(player: Player)
	local rate = CONFIG.rank_refresh_rate
	local groupid = CONFIG.groupid
	local userid = player.UserId
	local start = os.clock()
	local rank = FETCH_RANK(userid, groupid) or 0

	if player and player:IsDescendantOf(PLAYERS) then
		local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]
		PLAYER_RANKS[player] = rank
	
		if threads_waiting then
			for _, thread in threads_waiting do
				task.spawn(thread, rank)
			end
			THREADS_WAITING_FOR_PLAYERS[player] = nil
		end

		local time_diff = os.clock() - start
		if time_diff < rate then
			task.wait(rate - time_diff)
		end

		while PLAYER_RANKS[player] do
			local new_rank = FETCH_RANK(userid, groupid)

			if not PLAYER_RANKS[player] then 
				return
			end

			if new_rank and new_rank ~= rank then
				PLAYER_RANKS[player] = new_rank

				for _, callback_data in RANK_CHANGED_CALLBACKS do
					task.spawn(callback_data[1], player, new_rank, rank)
				end
				rank = new_rank
			end
			task.wait(rate)
		end
	end
end

local function init(new_config: { rank_refresh_rate: number?, groupid: number })
	if INITIATED then return end
	new_config.rank_refresh_rate = new_config.rank_refresh_rate or CONFIG.rank_refresh_rate
	CONFIG = table.freeze(new_config) :: typeof(CONFIG)
	INITIATED = true

	task.spawn(function()
		for _, player in PLAYERS:GetPlayers() do
			task.spawn(on_player_added, player)
		end
	end)

	PLAYERS.PlayerRemoving:Connect(on_player_removing)
	PLAYERS.PlayerAdded:Connect(on_player_added)
end

local function on_rank_changed(callback: RankChangedCallback): () -> ()
	local data = { callback }
	table.insert(RANK_CHANGED_CALLBACKS, data)

	return function()
		local index: number = table.find(RANK_CHANGED_CALLBACKS, data) :: any

		if index ~= 1 then
			local len = #RANK_CHANGED_CALLBACKS
			RANK_CHANGED_CALLBACKS[index] = RANK_CHANGED_CALLBACKS[len]
			RANK_CHANGED_CALLBACKS[len] = nil
		else
			RANK_CHANGED_CALLBACKS[1] = nil
		end
	end
end

local function get_rank(player: Player): number
	local rank = PLAYER_RANKS[player]

	if rank then
		return rank
	elseif player and player:IsDescendantOf(PLAYERS) then
		local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]

		if threads_waiting then
			table.insert(threads_waiting, coroutine.running())
		else
			THREADS_WAITING_FOR_PLAYERS[player] = { coroutine.running() }
		end
		return coroutine.yield()
	else
		error "[GROUPER] Player has left game too early"
	end
end

local function get_rank_and_role(player: Player): (number, string)
	local rank = get_rank(player)
	return rank, ROLE_CACHE[rank + 1]
end

local function is_in_group(player: Player): boolean
	return get_rank(player) ~= 0
end

local function get_role(player: Player): string
	return ROLE_CACHE[get_rank(player) + 1]
end

local exports = table.freeze {
	get_rank_and_role = get_rank_and_role,
	on_rank_changed = on_rank_changed,
	CONFIG = CONFIG :: typeof(CONFIG),
	is_in_group = is_in_group,
	players = PLAYER_RANKS,
	get_rank = get_rank,
	get_role = get_role,
	init = init,
}

return exports
