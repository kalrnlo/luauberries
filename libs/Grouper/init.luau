--!optimize 2
--!native
--!strict

-- Grouper
-- Used for getting the latest group rank or role of a player on the server,
-- and reducing groups api requests as only the server will make the requests
-- and then send down the rank & role for a player. 
-- Rather than using Player:GetRankInGroup() on the client, 
-- and end up constantly making api requests as Player:GetRankInGroup() 
-- only caches its result on the server
-- @kalrnlo
-- 28/05/2024

local GROUP_SERVICE = game:GetService("GroupService")
local PLAYERS = game:GetService("Players")

type FireRankChanged = (send_to_player: Player, player_whose_rank_changed: Player, rank: number, role: string) -> ()
type FireAllRankChanged = (player_whose_rank_changed: Player, rank: number, role: string) -> ()
type ReplicateRankUpdateCallback = (player: Player, rank: number, role: string) -> ()
type RankChangedCallback = (player: Player, new_rank: number, old_rank: number) -> ()
type Groups = { { Role: string, Rank: number, Id: number } }

export type ClientConfig = {
	connect_rank_changed: (callback: ReplicateRankUpdateCallback) -> ()
}

export type ServerConfig = {
	rank_refresh_rate: number?,
	fire_all_rank_changed: nil,
	fire_rank_changed: nil,
	groupid: number,
} |  {
	fire_all_rank_changed: FireAllRankChanged,
	fire_rank_changed: FireRankChanged,
	rank_refresh_rate: number?,
	groupid: number,
}

local FIRE_ALL_RANK_CHANGED: FireAllRankChanged
local NOOP = function<T...>(...: T...) end
local FIRE_RANK_CHANGED: FireRankChanged
local RANK_REFRESH_RATE: number
local DEFAULT_ROLE = "Guest"
local INITIATED = false
local GROUP_ID: number
local DEFAULT_RANK = 0

local THREADS_WAITING_FOR_PLAYERS = {} :: { [Player]: { thread } }
local RANK_CHANGED_CALLBACKS = {} :: { { RankChangedCallback } }
local IS_SERVER = game:GetService("RunService"):IsServer()
local GET_GROUPS_ASYNC = GROUP_SERVICE.GetGroupsAsync
local ROLE_CACHE = table.create(256, DEFAULT_ROLE)
local PLAYER_RANKS = {} :: { [Player]: number }

-- cursed using the first argument to tell if it was sucessful or not
-- but hey it works so
local function FETCH_RANK_AND_ROLE(userid: number): (number?, string)
	local success, groups: Groups = pcall(GET_GROUPS_ASYNC, GROUP_SERVICE, userid)
	
	if success then
		for _, group in groups do
			if group.Id ~= GROUP_ID then continue end
			local role = group.Role
			local rank = group.Rank
			ROLE_CACHE[rank + 1] = role
			return rank, role
		end

		-- player isn't in group, so we return 0 (the rank of a player not in the group)
		return DEFAULT_RANK, DEFAULT_ROLE
	else
		warn(`[GROUPER] Couldn't fetch rank for user {userid}\n\tgroup-service-err: {groups}`)
		return nil, DEFAULT_ROLE
	end
end

local function on_player_removing(player: Player)
	local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]

	if threads_waiting then
		THREADS_WAITING_FOR_PLAYERS[player] = nil
		table.clear(threads_waiting)
	end
	PLAYER_RANKS[player] = nil
end

local function on_player_added(player: Player)
	-- idc if this thread errors if the player leaves, its gonna be rare if that happens
	-- so if it does oh well, atleast i didnt create a new closure
	task.spawn(function(send_to_player: Player)
		for player, rank in PLAYER_RANKS do
			FIRE_RANK_CHANGED(send_to_player, player, rank, ROLE_CACHE[rank + 1])
		end
	end, player)

	local userid = player.UserId
	local start = os.clock()
	local rank, role = FETCH_RANK_AND_ROLE(userid)
	local rank = rank or 0

	if player and player:IsDescendantOf(PLAYERS) then
		local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]
		PLAYER_RANKS[player] = rank
	
		FIRE_ALL_RANK_CHANGED(player, rank, role)

		if threads_waiting then
			for _, thread in threads_waiting do
				task.spawn(thread, rank)
			end
			THREADS_WAITING_FOR_PLAYERS[player] = nil
		end

		local time_diff = os.clock() - start
		if time_diff < RANK_REFRESH_RATE then
			task.wait(RANK_REFRESH_RATE - time_diff)
		end

		while player and PLAYER_RANKS[player] do
			local new_rank, new_role = FETCH_RANK_AND_ROLE(userid)

			if not player or not PLAYER_RANKS[player] then
				return
			end

			print(new_rank, new_role)
			if new_rank and new_rank ~= rank then
				PLAYER_RANKS[player] = new_rank

				FIRE_ALL_RANK_CHANGED(player, new_rank, new_role)
				for _, callback_data in RANK_CHANGED_CALLBACKS do
					task.spawn(callback_data[1], player, new_rank, rank)
				end
				rank = new_rank
			end
			task.wait(RANK_REFRESH_RATE)
		end
	end
end

local function client_init(config: ClientConfig)
	if IS_SERVER then
		error("[GROUPER] Can only call ClientInit on the client")
	end
	if INITIATED then
		error("[GROUPER] Cannot initiate twice")
	end
	INITIATED = true

	config.connect_rank_changed(function(player, rank, role)
		-- print(`[GROUPER] client recieved rank data \n\tname: {player.Name}\n\tuserid: {player.UserId}\n\trank: {rank}\n\trole: {role}`)
		local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]
		local old_rank = PLAYER_RANKS[player]

		PLAYER_RANKS[player] = rank
		ROLE_CACHE[rank + 1] = role

		if threads_waiting then
			for _, thread in threads_waiting do
				task.spawn(thread, rank)
			end
			THREADS_WAITING_FOR_PLAYERS[player] = nil
		end
		
		for _, callback_data in RANK_CHANGED_CALLBACKS do
			task.spawn(callback_data[1], player, rank, old_rank)
		end
	end)

	PLAYERS.PlayerRemoving:Connect(on_player_removing)
end

local function server_init(config: ServerConfig)
	if not IS_SERVER then
		error("[GROUPER] Can only call ServerInit on the server")
	end
	if INITIATED then
		error("[GROUPER] Cannot initiate twice")
	end

	-- replication is optional if someone isnt using it
	FIRE_ALL_RANK_CHANGED = config.fire_all_rank_changed or NOOP
	FIRE_RANK_CHANGED = config.fire_rank_changed or NOOP
	RANK_REFRESH_RATE = config.rank_refresh_rate or 30
	GROUP_ID = config.groupid
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

-- having this yield, as in studio the rank isnt gotten immediatly like in-game
-- so this ends up returning 0
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
	is_in_group = is_in_group,
	players = PLAYER_RANKS,
	-- planning on adding an extra arg to rank & role for setting ranks & roles in
	-- the group
	rank = get_rank,
	role = get_role,

	init = table.freeze {
		server = server_init,
		client = client_init,
	},
}

return exports
