--!optimize 2
--!native

-- Grouper
-- Used for getting the latest group rank or role of a player on the server,
-- and reducing groups api requests as only the server will make the requests
-- and then send down the rank & role for a player. 
-- Rather than using Player:GetRankInGroup() on the client, 
-- and end up constantly making api requests as Player:GetRankInGroup() 
-- only caches its result on the server

local GroupService = game:GetService("GroupService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

type FireRankChanged = (send_to_player: Player, player_whose_rank_changed: Player, rank: number, role: string) -> ()
type FireAllRankChanged = (player_whose_rank_changed: Player, rank: number, role: string) -> ()
type ReplicateRankUpdateCallback = (player: Player, rank: number, role: string) -> ()
type RankChangedCallback = (player: Player, new_rank: number, old_rank: number) -> ()
type Groups = { { Role: string, Rank: number, Id: number } }
type FetchInfo = {
	last_fetched: number,
	is_fetching: boolean,
	rank: number,
}

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

local GET_GROUPS_ASYNC = GroupService.GetGroupsAsync
local FIRE_ALL_RANK_CHANGED: FireAllRankChanged
local NOOP = function<T...>(...: T...) end
local FIRE_RANK_CHANGED: FireRankChanged
local IS_SERVER = RunService:IsServer()
local RANK_REFRESH_RATE: number
local DEFAULT_ROLE = "Guest"
local INITIATED = false
local DEFAULT_RANK = 0
local GROUP_ID: number

local ROLE_HASH_CACHE = { [0] = DEFAULT_ROLE } :: { [number]: string }
local THREADS_WAITING_FOR_PLAYERS = {} :: { [Player]: { thread } }
local RANK_CHANGED_CALLBACKS = {} :: { { RankChangedCallback } }
local PLAYER_FETCH_INFO = {} :: { [Player]: FetchInfo }
local ROLE_CACHE = table.create(256, DEFAULT_ROLE)
local PLAYER_RANKS = {} :: { [Player]: number }

-- cursed using the first argument to tell if it was sucessful or not
-- but hey it works so
local function FETCH_RANK_AND_ROLE(userid: number): (number?, string)
	local success, groups: Groups = pcall(GET_GROUPS_ASYNC, GroupService, userid)
	
	if success then
		for _, group in groups do
			if group.Id ~= GROUP_ID then continue end
			local role = group.Role
			local rank = group.Rank

			ROLE_HASH_CACHE[rank] = role
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

-- having this yield, as in studio the rank isnt gotten immediatly like in-game
-- so this ends up returning 0
local function GET_RANK(player: Player): number
	local rank = PLAYER_RANKS[player]

	if rank then
		return rank
	elseif player and player:IsDescendantOf(Players) then
		local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]

		if threads_waiting then
			table.insert(threads_waiting, coroutine.running())
		else
			THREADS_WAITING_FOR_PLAYERS[player] = { coroutine.running() }
		end
		return coroutine.yield()
	else
		error("[GROUPER] player has left game too early")
	end
end

local function fetcher(player: Player, fetchinfo: FetchInfo)
	local new_rank, new_role = FETCH_RANK_AND_ROLE(player.UserId)

	if not player or not PLAYER_RANKS[player] then
		return
	end

	local rank = fetchinfo.rank

	if new_rank and new_rank ~= rank then
		PLAYER_RANKS[player] = new_rank
		fetchinfo.rank = new_rank

		FIRE_ALL_RANK_CHANGED(player, new_rank, new_role)
		for _, callback_data in RANK_CHANGED_CALLBACKS do
			task.spawn(callback_data[1], player, new_rank, rank)
		end
	end

	fetchinfo.last_fetched = os.time()
	fetchinfo.is_fetching = false
end

local function on_player_removing(player: Player)
	local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]

	if threads_waiting then
		THREADS_WAITING_FOR_PLAYERS[player] = nil

		for _, thread in threads_waiting do
			-- this is such an extreme edge case that will most likely never happen
			-- and if it does, most code where ur checking for ranks isnt that critical
			-- ie code that uses grouper doesnt deal w loading datastores ect ect
			coroutine.close(thread)
		end
	end
	PLAYER_FETCH_INFO[player] = nil
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
	local fetch_time = os.clock()
	local rank, role = FETCH_RANK_AND_ROLE(userid)
	local rank = rank or 0

	if player and player:IsDescendantOf(Players) then
		local threads_waiting = THREADS_WAITING_FOR_PLAYERS[player]
		PLAYER_RANKS[player] = rank
	
		FIRE_ALL_RANK_CHANGED(player, rank, role)

		if threads_waiting then
			for _, thread in threads_waiting do
				task.spawn(thread, rank)
			end
			THREADS_WAITING_FOR_PLAYERS[player] = nil
		end

		PLAYER_FETCH_INFO[player] = {
			last_fetched = fetch_time,
			is_fetching = false,
			rank = rank
		}
	end
end

local function fetch_loop()
	for player, fetchinfo in PLAYER_FETCH_INFO do
		if 
			os.time() - fetchinfo.last_fetched >= RANK_REFRESH_RATE and 
			not fetchinfo.is_fetching
		then
			fetchinfo.is_fetching = true
			task.defer(fetcher, player, fetchinfo)
		end
	end
end

local grouper = { rank = GET_RANK, init = {} }

function grouper.init.client(config: ClientConfig)
	if IS_SERVER then
		error("[GROUPER] can only call client_init on the client")
	end
	if INITIATED then
		error("[GROUPER] cannot initiate twice")
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

	Players.PlayerRemoving:Connect(on_player_removing)
end

function grouper.init.server(config: ServerConfig)
	if not IS_SERVER then
		error("[GROUPER] can only call server_init on the server")
	end
	if INITIATED then
		error("[GROUPER] cannot initiate twice")
	end

	-- replication is optional if someone isnt using it
	FIRE_ALL_RANK_CHANGED = config.fire_all_rank_changed or NOOP
	FIRE_RANK_CHANGED = config.fire_rank_changed or NOOP
	RANK_REFRESH_RATE = config.rank_refresh_rate or 30
	GROUP_ID = config.groupid
	INITIATED = true
	
	task.spawn(function()
		for _, player in Players:GetPlayers() do
			task.spawn(on_player_added, player)
		end
	end)

	Players.PlayerRemoving:Connect(on_player_removing)
	RunService.PostSimulation:Connect(fetch_loop)
	Players.PlayerAdded:Connect(on_player_added)
end

function grouper.on_rank_changed(callback: RankChangedCallback): () -> ()
	local callback_info = { callback }
	table.insert(RANK_CHANGED_CALLBACKS, callback_info)

	return function()
		local index: number = table.find(RANK_CHANGED_CALLBACKS, callback_info) :: any

		if index ~= 1 then
			local len = #RANK_CHANGED_CALLBACKS
			RANK_CHANGED_CALLBACKS[index] = RANK_CHANGED_CALLBACKS[len]
			RANK_CHANGED_CALLBACKS[len] = nil
		else
			RANK_CHANGED_CALLBACKS[1] = nil
		end
	end
end

function grouper.rank_and_role(player: Player): (number, string)
	local rank = GET_RANK(player)
	return rank, ROLE_CACHE[rank + 1]
end

function grouper.is_in_group(player: Player): boolean
	return GET_RANK(player) ~= 0
end

function grouper.role(player: Player): string
	return ROLE_CACHE[GET_RANK(player) + 1]
end

function grouper.players(): { [Player]: number }
	return table.clone(PLAYER_RANKS)
end

-- using role_hash_cache because 
function grouper.roles(): { [number]: string }
	return table.clone(ROLE_HASH_CACHE)
end

table.freeze(grouper.init)
return table.freeze(grouper)
