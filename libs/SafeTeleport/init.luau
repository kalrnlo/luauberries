--!strict

-- Safe Teleport
-- modified version of robloxs safe teleport function on the docs for TeleportAsync with types
-- and api improvements
-- @kalrnlo
-- 07/05/2024

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local retryer = require("libs/Retryer")

type SafeTeleportPrototype = { __call: (self: SafeTeleport, place_id: number, players_or_player: {Player} | Player, info: SafeTeleportInfo?) -> (boolean, SafeTeleportResult)}
type SafeTeleport = typeof(setmetatable({} :: {
    ATTEMPT_LIMIT: number,
    RETRY_DELAY: number,
    FLOOD_DELAY: number
}, {} :: SafeTeleportPrototype))

export type SafeTeleportResult = {
    reserved_server_access_code: string,
    private_server_id: string,
}

export type SafeTeleportInfo = {
    reserve_server: boolean?,
    data: { [string]: any }?,
    access_code: string?,
    jobid: string?,
}

local failed_teleport_result: SafeTeleportResult = table.freeze {
    reserved_server_access_code = "",
    private_server_id = "0",
}
local self = {
    ATTEMPT_LIMIT = 5,
    RETRY_DELAY = 1,
    FLOOD_DELAY = 15,
}

local teleport_async = TeleportService.TeleportAsync

local function safe_teleport(place_id: number, players_or_player: {Player} | Player, opts: TeleportOptions?): (boolean, SafeTeleportResult)
	local success, result = retryer.delay(
        self.RETRY_DELAY, 
        self.ATTEMPT_LIMIT,
        teleport_async, 
        TeleportService,  
        place_id, 
        if type(players_or_player) == "table" then players_or_player else table.create(1, players_or_player), 
        opts
    )

	if success then
        return success, table.freeze {
            reserved_server_access_code = result.ReservedServerAccessCode,
            private_server_id = result.PrivateServerId,
        }
    else
		warn(`[SAFE_TELEPORT]: unsucessful teleport\n\tteleport_async_err: {result}`)
        return success, failed_teleport_result
	end
end

local function safe_teleport_call(self: SafeTeleport, place_id: number, players_or_player: {Player} | Player, info: SafeTeleportInfo?): (boolean, SafeTeleportResult)
    -- freezing it here, as somebody might want to configure the delays n stuff before its frozen
    if not table.isfrozen(self :: any) then 
        table.freeze(self) 
    end

    if info then
        local opts = Instance.new("TeleportOptions")
        opts.ReservedServerAccessCode = info.access_code :: any
        opts.ShouldReserveServer = info.reserve_server :: any
        opts.ServerInstanceId = info.jobid :: any
        opts:SetTeleportData(info.data)
        return safe_teleport(place_id, players_or_player, opts)
    else
        return safe_teleport(place_id, players_or_player)
    end
end

TeleportService.TeleportInitFailed:Connect(function(player, result, err, place_id, opts)
	if result == Enum.TeleportResult.Flooded then
		task.wait(self.FLOOD_DELAY)
	elseif result == Enum.TeleportResult.Failure then
		task.wait(self.RETRY_DELAY)
	else
		-- if the teleport is invalid, report the error instead of retrying
		error(`[SAFE_TELEPORT]: teleport failed\n\tresult_name: {result.Name}\n\terr: {err}`)
	end

	safe_teleport(place_id, player, opts)
end)

local mt = {
    __call = safe_teleport_call
}
mt.__index = mt 

local export: SafeTeleport = setmetatable(self, table.freeze(mt)) :: any

return export