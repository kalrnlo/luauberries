
-- playerzone
-- simple util module for detecting players in rectangular zones

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local character = require("../character")

export type ZoneType = "WHITELIST" | "BLACKLIST"

type BaseZone = {
	callback: (character: character.Character, player: Player) -> (),
	blacklist: { PlayerZoneInfo },
	size_halved_x: number,
	size_halved_y: number,
	size_halved_z: number,
	cframe: CFrame,
	size: Vector3,
	id: number,
}

type PlayerZoneInfo = {
	character: character.Character,
	rootpart: BasePart,
	position: Vector3,
	player: Player,
}

export type WhitelistZone = BaseZone & {
	whitelisted: { Player },
	type: "WHITELIST",
	blacklisted: nil,
}

export type BlacklistZone = BaseZone & {
	blacklisted: { Player },
	type: "BLACKLIST",
	whitelisted: nil,
}

export type Zone = WhitelistZone | BlacklistZone

type BaseZoneInfo = {
	callback: (character: character.Character, player: Player) -> (),
	cframe: CFrame,
	size: Vector3,
}

local POINT_TO_OBJECT_SPACE = CFrame.identity.PointToObjectSpace
local WEAK = table.freeze({ __mode = "v" })

local WHITELIST_ZONES = (setmetatable({}, WEAK) :: any) :: { WhitelistZone }
local BLACKLIST_ZONES = (setmetatable({}, WEAK) :: any) :: { BlacklistZone }
local ZONES = (setmetatable({}, WEAK) :: any) :: { Zone }
local PLAYER_ZONE_INFO = {} :: { PlayerZoneInfo }
local NEXT_ID = 1

local function FIND_AND_REMOVE_ZONE_INFO(tbl: { PlayerZoneInfo }, player: Player)
	for index, player_zone_info in tbl do
		if player_zone_info.player == player then
			table.remove(tbl, index)
		end
	end
end

local function FIND_AND_REMOVE<V>(tbl: { V }, v: V)
	local index = table.find(tbl, v)

	if index then
		table.remove(tbl, index)
	end
end

local function remove(zone: Zone, player: Player)
	FIND_AND_REMOVE_ZONE_INFO(zone.blacklist, player)
	FIND_AND_REMOVE(
		if zone.type == "WHITELIST" then zone.whitelisted else zone.blacklisted, 
		player
	)
end

local function insert(zone: Zone, player: Player)
	local whitelisted = zone.whitelisted :: any
	local blacklisted = zone.blacklisted :: any

	if zone.type == "WHITELIST" and not table.find(whitelisted, player) then
		table.insert(whitelisted, player)
		FIND_AND_REMOVE_ZONE_INFO(zone.blacklist, player)
	elseif not table.find(blacklisted, player) then
		local player_zone_info: PlayerZoneInfo
		local character = player.Character

		table.insert(blacklisted, player)

		if character then
			for _, player_zone_info in PLAYER_ZONE_INFO do
				if player_zone_info.player == player then
					local blacklist = zone.blacklist
		
					if not table.find(blacklist, player_zone_info) then
						table.insert(blacklist, player_zone_info)
					end
					return
				end
			end
		end
	end
end

local function create(info: BaseZoneInfo & { type: ZoneType? }): Zone
	local size = info.size - Vector3.one
	local size_halved = size / 2
	local zone = {
		blacklist = setmetatable({}, WEAK) :: any,
		type = info.type or "BLACKLIST" :: any,
		size_halved_x = size_halved.X,
		size_halved_y = size_halved.Y,
		size_halved_z = size_halved.Z,
		callback = info.callback,
		cframe = info.cframe,
		id = NEXT_ID,
		size = size,
	}

	if info.type == "WHITELIST" then
		zone.whitelisted = {}
		table.insert(WHITELIST_ZONES, zone)
	else
		zone.blacklisted = {} :: any
		table.insert(BLACKLIST_ZONES, zone :: any)
	end

	table.insert(ZONES, zone)
	NEXT_ID += 1
	return zone :: any
end

do

	RunService.PostSimulation:Connect(@native function()
		for _, player_zone_info in PLAYER_ZONE_INFO do
			player_zone_info.position = player_zone_info.rootpart.CFrame.Position
		end

		-- weak tables skip over the __mode key in iteration!
		for key, zone in ZONES do
			local size_halved_x = zone.size_halved_x
			local size_halved_y = zone.size_halved_y
			local size_halved_z = zone.size_halved_z
			local callback = zone.callback
			local cframe = zone.cframe
		
			for _, player_zone_info in zone.blacklist :: { PlayerZoneInfo } do
				local offset = (POINT_TO_OBJECT_SPACE(cframe, player_zone_info.position))
				local is_in_box = math.abs(offset.X) <= size_halved_x
					and math.abs(offset.Y) <= size_halved_y
					and math.abs(offset.Z) <= size_halved_z

				if is_in_box then
					callback(player_zone_info.character, player_zone_info.player)
				end
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		character.removing(player, function(character)
			FIND_AND_REMOVE_ZONE_INFO(PLAYER_ZONE_INFO, player)
		end)
		character.added(player, function(character)
			local rootpart: BasePart = character.PrimaryPart :: any
			local player_zone_info = {
				position = rootpart.CFrame.Position,
				character = character,
				rootpart = rootpart,
				player = player,
			}

			table.insert(PLAYER_ZONE_INFO, player_zone_info)

			for _, zone in WHITELIST_ZONES do
				if not table.find(zone.whitelisted, player) then
					table.insert(zone.blacklist, player_zone_info)
				end
			end

			for _, zone in BLACKLIST_ZONES do
				if table.find(zone.blacklisted, player) then
					table.insert(zone.blacklist, player_zone_info)
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		for _, zone in WHITELIST_ZONES do
			FIND_AND_REMOVE(zone.whitelisted, player)
		end

		for _, zone in BLACKLIST_ZONES do
			FIND_AND_REMOVE(zone.blacklisted, player)
		end
	end)
end

return table.freeze({
	create = (create :: any) :: ((info: BaseZoneInfo & { type: "BLACKLIST"? }) -> BlacklistZone) & 
		((info: BaseZoneInfo & { type: "WHITELIST" }) -> WhitelistZone),
	remove = remove,
	insert = insert,
})