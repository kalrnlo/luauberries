--!strict

-- Safe Teleport
-- modified version of robloxs safe teleport function on the docs for TeleportAsync with types
-- and api improvements
-- @kalrnlo
-- 07/05/2024

local teleport_service = game:GetService("TeleportService")
local retryer = require(script.Parent.retryer)

local ATTEMPT_LIMIT = 5
local RETRY_DELAY = 1
local FLOOD_DELAY = 15

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

local function PARSE_INFO(info: SafeTeleportInfo)
    local opts = Instance.new("TeleportOptions")
    opts.ReservedServerAccessCode = info.reserved_server_acess_code :: any
    opts.ShouldReserveServer = info.reserve_server :: any
    opts.ServerInstanceId = info.job_id :: any
    return opts
end

local function SAFE_TELEPORT(place_id: number, players_or_player: {Player} | Player, info: SafeTeleportInfo): (boolean, SafeTeleportResult)
	local success, result = retryer.delay(
        RETRY_DELAY, 
        ATTEMPT_LIMIT,
        teleport_service.TeleportAsync, 
        teleport_service,  
        place_id, 
        if type(players_or_player) == "table" then players_or_player else table.create(1, players_or_player), 
        if info then PARSE_INFO(info) else nil
    )

	if not success then
		warn(`[SAFE_TELEPORT]: unsucessful teleport\n\tteleport_async_err: {result}`)
	end

    return success, table.freeze {
        reserved_server_acess_code = result.ReservedServerAccessCode,
        private_server_id = result.PrivateServerId,
    }
end

teleport_service.TeleportInitFailed:Connect(function(player, result, err, place_id, opts)
	if result == Enum.TeleportResult.Flooded then
		task.wait(FLOOD_DELAY)
	elseif result == Enum.TeleportResult.Failure then
		task.wait(RETRY_DELAY)
	else
		-- if the teleport is invalid, report the error instead of retrying
		error(`[SAFE_TELEPORT]: teleport failed\n\tresult_name: {result.Name}\n\terr: {err}`)
	end

	SAFE_TELEPORT(place_id, player, opts)
end)

return SAFE_TELEPORT