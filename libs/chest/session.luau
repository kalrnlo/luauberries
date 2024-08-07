--!native

-- session
-- util for dealing with session locks

local t = require("types")

local SESSION = {}

local function IS_EXPIRED(timestamp: number)
	return os.time() - timestamp >= 60
end

function SESSION.CAN_SAVE(saveinfo: t.SaveInfo, our_uuid: string): boolean
	local is_expired = IS_EXPIRED(saveinfo.timestamp)

	return saveinfo.lock_uuid == our_uuid -- Case 1: Locked by us
		or (saveinfo.is_locked and is_expired) -- Case 2: Locked, expired
		or is_expired -- Case 3: expired
end

function SESSION.CAN_LOCK(saveinfo: t.SaveInfo): boolean
	local is_expired = IS_EXPIRED(saveinfo.timestamp or 0)
	local is_locked = saveinfo.is_locked

	return not is_locked -- Case 1: Not locked
		or (is_locked and is_expired) -- Case 2: Locked, expired
		or is_expired -- Case 3: expired
end

return table.freeze(SESSION)