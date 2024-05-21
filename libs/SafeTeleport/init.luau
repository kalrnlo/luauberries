--!strict

-- Safe Teleport
-- modified version of robloxs safe teleport function on the docs for TeleportAsync with types
-- and api improvements
-- @kalrnlo
-- 07/05/2024

local teleport_service = game:GetService("TeleportService")
local retryer = require(script.Parent.retryer)
local metaize = require(script.Parent.metaize)

type SafeTeleportPrototype = { __call: (self: SafeTeleport, place_id: number, players_or_player: {Player} | Player, info: SafeTeleportInfo?) -> (boolean, SafeTeleportResult)}
type SafeTeleport = typeof(setmetatable({} :: {
	ATTEMPT_LIMIT: number,
	RETRY_DELAY: number,
	FLOOD_DELAY: number
}, {} :: SafeTeleportPrototype))

export type SafeTeleportResult = {
	reserved_server_acess_code: string,
	private_server_id: number,
}

export type SafeTeleportInfo = {
	reserved_server_acess_code: string?,
	reserve_server: boolean?,
	place_id: number,
	job_id: string?,
}

local EMPTY = table.freeze {}
local BASE = {
	ATTEMPT_LIMIT = 5
	RETRY_DELAY = 1
	FLOOD_DELAY = 15
}

local function SAFE_TELEPORT(place_id: number, players_or_player: {Player} | Player, opts: TeleportOptions?): (boolean, SafeTeleportResult)
	local success, result = retryer.delay(
		BASE.RETRY_DELAY, 
		BASE.ATTEMPT_LIMIT,
		teleport_service.TeleportAsync, 
		teleport_service,  
		place_id, 
		if type(players_or_player) == "table" then players_or_player else table.create(1, players_or_player), 
		opts
	)

	if success then
		return success, table.freeze {
			reserved_server_acess_code = result.ReservedServerAccessCode,
			private_server_id = result.PrivateServerId,
		}
	else
		warn(`[SAFE_TELEPORT]: unsucessful teleport\n\tteleport_async_err: {result}`)
		return success, EMPTY :: any
	end
end

local function safe_teleport_call(self: SafeTeleport, place_id: number, players_or_player: {Player} | Player, info: SafeTeleportInfo?): (boolean, SafeTeleportResult)
	if not table.isfrozen(self :: any) then table.freeze(self) end

	if info then
		local opts = Instance.new("TeleportOptions")
		opts.ReservedServerAccessCode = info.reserved_server_acess_code :: any
		opts.ShouldReserveServer = info.reserve_server :: any
		opts.ServerInstanceId = info.job_id :: any
		return SAFE_TELEPORT(place_id, players_or_player, opts)
	else
		return SAFE_TELEPORT(place_id, players_or_player)
	end
end

teleport_service.TeleportInitFailed:Connect(function(player, result, err, place_id, opts)
	if result == Enum.TeleportResult.Flooded then
		task.wait(BASE.FLOOD_DELAY)
	elseif result == Enum.TeleportResult.Failure then
		task.wait(BASE.RETRY_DELAY)
	else
		-- if the teleport is invalid, report the error instead of retrying
		error(`[SAFE_TELEPORT]: teleport failed\n\tresult_name: {result.Name}\n\terr: {err}`)
	end

	SAFE_TELEPORT(place_id, player, opts)
end)

local export: SafeTeleport = setmetatable(BASE, metaize {
	__call = safe_teleport_call
}) :: any

return export