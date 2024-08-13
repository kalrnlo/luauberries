
-- safe teleport
-- modified version of robloxs safe teleport function on the docs for TeleportAsync with types
-- and api improvements

local TeleportService = game:GetService("TeleportService")
local retryer = require("../Retryer")

type SafeTeleportPrototype = { 
    __call: (
        self: SafeTeleport, placeid: number, players_or_player: { Player } | Player, info: SafeTeleportInfo?
    ) -> (boolean, SafeTeleportResult)
}

type SafeTeleport = typeof(setmetatable({} :: {
    ATTEMPT_LIMIT: number,
    RETRY_DELAY: number,
    FLOOD_DELAY: number
}, {} :: SafeTeleportPrototype))

export type SafeTeleportResult = {
    private_server_id: string,
    access_code: string,
}

export type SafeTeleportInfo = {
    reserve_server: boolean?,
    data: { [string]: any }?,
    access_code: string?,
    jobid: string?,
}

local TELEPORT_ASYNC = TeleportService.TeleportAsync
local FAILED_RESULT: SafeTeleportResult = table.freeze({
    private_server_id = "0",
    access_code = "",
})
local ATTEMPT_LIMIT = 5
local FLOOD_DELAY = 15
local RETRY_DELAY = 1

local function safe_teleport(placeid: number, players_or_player: {Player} | Player, opts: TeleportOptions?): (boolean, SafeTeleportResult)
	local success, result = retryer.delay(
        RETRY_DELAY, ATTEMPT_LIMIT, TELEPORT_ASYNC, TeleportService,  
        placeid, 
        if type(players_or_player) == "table" then players_or_player else { players_or_player }, 
        opts
    )

	if success then
        return success, table.freeze({
            access_code = result.ReservedServerAccessCode,
            private_server_id = result.PrivateServerId,
        })
    else
		warn(`[SAFE TELEPORT]: unsucessful teleport\n\tteleport_async_err: {result}`)
        return success, FAILED_RESULT
	end
end

local function safe_teleport_call(self: SafeTeleport, placeid: number, players_or_player: {Player} | Player, info: SafeTeleportInfo?): (boolean, SafeTeleportResult)
    -- freezing it here, as somebody might want to configure the delays n stuff before its frozen
    if not table.isfrozen(self :: any) then 
        table.freeze(self) 
        ATTEMPT_LIMIT = self.ATTEMPT_LIMIT
        RETRY_DELAY = self.RETRY_DELAY
        
    end

    if info then
        local opts = Instance.new("TeleportOptions")
        opts.ReservedServerAccessCode = info.access_code :: any
        opts.ShouldReserveServer = info.reserve_server :: any
        opts.ServerInstanceId = info.jobid :: any
        opts:SetTeleportData(info.data)
        return safe_teleport(placeid, players_or_player, opts)
    else
        return safe_teleport(placeid, players_or_player)
    end
end

do

    TeleportService.TeleportInitFailed:Connect(function(player, result, err, place_id, opts)
	    if result == Enum.TeleportResult.Flooded then
		    task.wait(FLOOD_DELAY)
	    elseif result == Enum.TeleportResult.Failure then
	    	task.wait(RETRY_DELAY)
	    else
		    -- if the teleport is invalid, report the error instead of retrying
	    	error(`[SAFE TELEPORT]: teleport failed\n\tresult_type: {result.Name}\n\terror: {err}`)
	    end

	    safe_teleport(place_id, player, opts)
    end)

end

return setmetatable({
    ATTEMPT_LIMIT = ATTEMPT_LIMIT,
    FLOOD_DELAY = FLOOD_DELAY,
    RETRY_DELAY = RETRY_DELAY,
}, table.freeze({ __call = safe_teleport_call })) :: SafeTeleport