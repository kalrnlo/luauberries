--!optimize 2
--!native
--!strict

-- 🐟 Grouper
-- Used for getting the latest group rank or role of a player on the server.
-- @Kalrnlo
-- 19/03/2024

local GroupService = game:GetService("GroupService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

export type RankChangedCallback = (Player: Player, NewRank: number, OldRank: number) -> ()

export type GroupInfo = {
	Roles: {
		{
			Name: string,
			Rank: number,
		}
	},
	Owner: {
		Name: string,
		Id: number
	},

	Description: string,
	EmblemUrl: string,
	Name: string,
	Id: number,
}

local HasFetchedRolesSucessfullyBefore = false
local EmptyPositionValue = "nil" :: any
local DefualtRole = "Guest"
local HasInitiated = false
local DefualtRank = 0
local Config = {
	DelayBetwenRetrysForFetchingRoles = 10,
	MaxRetrysForFetchingRoles = 20,
	RankRefreshRate = 30,
	GroupId = 0,
}

-- {[PositionInCache] = Player | "nil"}
-- not using nil but rather "nil", as otherwise we cant use table.find() to find the first non taken index
local PlayerCachePositions = table.create(Players.MaxPlayers, EmptyPositionValue) :: {[number]: Player | "nil"}
local PlayerRefreshTimes = buffer.create(Players.MaxPlayers * 4)
-- {[UserId] = {Thread}}
local ThreadsWaitingForPlayers = {} :: {[number]: {thread}}
local RankChangedCallbacks = {} :: {{RankChangedCallback}}
local PlayerRankCache = buffer.create(Players.MaxPlayers)
local RoleCache = table.create(256, DefualtRole)
local Grouper

local function InternalRefreshPlayer(Player: Player, PlayerOffset: number)
	local Success, Groups = pcall(GroupService.GetGroupsAsync, GroupService, Player.UserId)
	
	if Success then
		local OldRank = buffer.readu8(PlayerRankCache, PlayerOffset)
	
		for _, Group in Groups do
			if Group.Id ~= Config.GroupId then continue end
			local NewRank = Group.Rank
			
			if NewRank ~= OldRank then
				buffer.writeu8(PlayerRankCache, PlayerOffset, NewRank)

				for _, Callback in RankChangedCallbacks do
					task.spawn(Callback[1], Player, NewRank, OldRank)
				end
			end
			break
		end
	else
		warn(`[Grouper] InternalRefreshPlayer couldn't get groups for Player {Player.UserId}\n\tGetGroupsAsyncError: {Groups}`)
	end
	
	return Success
end

local function RankUpdateLoop()
	while true do
		local DeltaTime = RunService.Heartbeat:Wait()
	
		for Position, PlayerAtPosition in PlayerCachePositions do
			if PlayerAtPosition == EmptyPositionValue then continue end
			local RefreshPosition = if Position ~= 1 then Position + 3 else 0
			local Diffrence = (os.clock() - DeltaTime) - buffer.readu32(PlayerRefreshTimes, RefreshPosition)		

			if Diffrence >= Config.RankRefreshRate then
				buffer.writeu32(PlayerRefreshTimes, RefreshPosition, os.clock())
				task.defer(InternalRefreshPlayer, PlayerAtPosition :: any, if Position ~= 1 then Position else 0)
			end
		end
	end
end

local function OnPlayerRemoving(Player: Player)
	local Position = table.find(PlayerCachePositions, Player)
	
	if Position then
		PlayerCachePositions[Position] = EmptyPositionValue
	end
end

local function OnPlayerAdded(Player: Player)
	-- Player:GetRankInGroup/GetRoleInGroup can error if the server has some HTTP error
	-- or the GroupsAPI is down at the time, so its in a pcall because of that
	local Success, Rank = pcall(Player.GetRankInGroup, Player, Config.GroupId)
	local ActualRank = if type(Rank) == "number" then Rank else 0
	local LastTimeChecked = os.clock()
	
	-- PlayerCachePositions is a table the size of the MaxPlayers for the server
	-- so therefor it will always have an empty slot whenever a player joins
	local PlayerPosition = table.find(PlayerCachePositions, EmptyPositionValue) :: number
	PlayerCachePositions[PlayerPosition] = Player
	
	buffer.writeu8(
        PlayerRankCache,
        if PlayerPosition ~= 1 then PlayerPosition else 0,
        ActualRank
    )
	buffer.writeu32(
		PlayerRefreshTimes,
		if PlayerPosition ~= 1 then PlayerPosition + 3 else 0,
		LastTimeChecked
	)

	if ThreadsWaitingForPlayers[Player.UserId] then
		for _, Thread in ThreadsWaitingForPlayers[Player.UserId] do
			task.spawn(Thread, ActualRank)
		end
		ThreadsWaitingForPlayers[Player.UserId] = nil
	end
	-- Just here incase if the player doesnt get removed by the player removing callback
	-- never had an issue with that, but it might happen so this is here
	if not Player:IsDescendantOf(Players) then
		PlayerCachePositions[PlayerPosition] = EmptyPositionValue
	end
	if not Success then
		warn(`[Grouper] OnPlayerAdded couldn't get rank for Player {Player.UserId}\n\tGetRankInGroupError: {Rank}`)
	end
end

local function OnRankChanged(Callback: RankChangedCallback): (() -> ())
	local CallbackData = table.create(1, Callback)
	table.insert(RankChangedCallbacks, CallbackData)

	return function()
		if #RankChangedCallbacks > 1 then
			local Index = table.find(RankChangedCallbacks, CallbackData) :: number
			RankChangedCallbacks[Index] = RankChangedCallbacks[#RankChangedCallbacks]
			RankChangedCallbacks[#RankChangedCallbacks] = nil
		else
			RankChangedCallbacks[1] = nil
		end
	end
end

-- function for yielding until a players data is added
-- incase ie Grouper.GetRank(Player) is called before that
-- player has been added to the cache
-- that then returns the players data once theyve been added to the cache
-- this issue only appears in studio, but might appear in game so this exists
local function GetRank(Player: Player): number
	local CachePosition = table.find(PlayerCachePositions, Player)

	if CachePosition then
		return buffer.readu8(PlayerRankCache, CachePosition)
	elseif Player:IsDescendantOf(Players) then
		local ThreadList = ThreadsWaitingForPlayers[Player.UserId]

		if ThreadList then
			table.insert(ThreadList, coroutine.running())
		else
			ThreadsWaitingForPlayers[Player.UserId] = { coroutine.running() }
		end
		return coroutine.yield()
	else
		return 0
	end
end

local function GetRankAndRole(Player: Player): (number, string)
	local Rank = GetRank(Player)
	return Rank, RoleCache[Rank + 1]
end

local function GetRoleForRank(Rank: number): string
	if Rank > 255 or Rank < 0 then
		error("[Grouper] Rank has to be in range 0..255")
	else
		return RoleCache[Rank + 1]		
	end	
end
			
local function IsInGroup(Player: Player): boolean
	return GetRank(Player) > 0
end
			
local function GetRole(Player: Player): string
	return RoleCache[GetRank(Player) + 1]
end

local function RefreshRoleCache(): boolean
	local Success, GroupInfo: GroupInfo = pcall(GroupService.GetGroupInfoAsync, GroupService, Config.GroupId)
	
	if Success then
		Grouper.HasFetchedRolesSucessfullyBefore = true
		HasFetchedRolesSucessfullyBefore = true

		for _, RoleData in GroupInfo.Roles do
			RoleCache[RoleData.Rank + 1] = RoleData.Name
		end
	else
		warn(`[Grouper] Failed to get group roles\n\tGetGroupInfoAsyncError: {GroupInfo}`)
	end

	return Success
end
			
local function Init()
	if HasInitiated then
		error("[Grouper] Cannot initate more than once without cleaning up")
	else
		HasInitiated = true
	end
	
	local Success = RefreshRoleCache()
	local Retrys = 0
				
	repeat
		task.wait(Config.DelayBetwenRetrysForFetchingRoles)
		Success = RefreshRoleCache()
		Retrys += 1
		
		if Retrys == Config.MaxRetrysForFetchingRoles then
			warn("[Grouper] Hit max retrys for trying to fetch roles")
			break
		end
	until Success
	
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	Players.PlayerAdded:Connect(OnPlayerAdded)
	task.spawn(RankUpdateLoop)

	for _, Player in Players:GetPlayers() do
		if table.find(PlayerCachePositions, Player) then continue end
		task.spawn(OnPlayerAdded, Player)
	end
end

-- doing this so the exports are frozen, and having HasFetchedRolesSucessfullyBefore in its own table
-- because it needs to be mutable whilst the rest should be read-only
local immutable_exports = table.freeze {
	PlayerCachePositions = PlayerCachePositions,
	RefreshRoleCache = RefreshRoleCache,
	PlayerRankCache = PlayerRankCache,
	GetRankAndRole = GetRankAndRole,
	GetRoleForRank = GetRoleForRank,
	OnRankChanged = OnRankChanged,
	IsInGroup = IsInGroup,
	RoleCache = RoleCache,
	GetRole = GetRole,
	GetRank = GetRank,
	Config = Config,
	Init = Init,
}
local mutable_exports = {
	HasFetchedRolesSucessfullyBefore = false
}

Grouper = (setmetatable(mutable_exports, immutable_exports) :: any) :: typeof(immutable_exports) & typeof(mutable_exports)

return Grouper