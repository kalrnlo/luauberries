
-- raw update
-- util for wrapping update async so its easier to use

local retryer = require("libs/retryer")
local t = require("types")

-- exists so the typechecker doesnt yell at me
local function PACK_VARADIC(...: any): { any }
	return { ... }
end

local function RAW_UPDATE_ASYNC<Value, A...>(
	chest: t.Chest<Value>,
	key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	...: A...
): (Value, DataStoreKeyInfo)
	-- doing this to not get a type error
	local packed_args = PACK_VARADIC(...)
	
	return chest.datastore:UpdateAsync(key, 
		function(global_value: Value, global_keyinfo: DataStoreKeyInfo): (Value?, { number }?, t.SaveInfo?)
			local global_saveinfo = global_keyinfo:GetMetadata()
			local global_userids = global_keyinfo:GetUserIds()
			local new_value, new_save_info, new_userids = f(
				global_value, global_saveinfo or {} :: any, 
				global_userids, unpack(packed_args :: any)
			)

			if new_save_info then
				return new_value, new_userids or global_userids, new_save_info or global_saveinfo
			else
				return nil
			end
		end
	)
end

local raw_update_mt = {}

function raw_update_mt.__call<S, Value, A...>(
	self: S,
	chest: t.Chest<Value>,
	key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	...: A...
): (boolean, Value, DataStoreKeyInfo)
	return pcall(RAW_UPDATE_ASYNC, chest, key, f, ...)
end

local raw_update = setmetatable({}, raw_update_mt)

function raw_update.retryC<Value, A...>(
	chest: t.Chest<Value>,
	key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	...: A...
): (boolean, Value, DataStoreKeyInfo)

end

local function PCALL_RAW_UPDATE_ASYNC<S, Value, A...>(
	self: S,
	chest: t.Chest<Value>,
	key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	...: A...
): (boolean, Value, DataStoreKeyInfo)

end


local function RETRY_RAW_UPDATE_ASYNC<Value, A...>(
	chest: Chest<Value>,
	key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	...: A...
): (boolean, Value, DataStoreKeyInfo)

	return retryer.exp(
		chest.time_between_attempts, chest.retry_exponent, chest.max_attempts,
		RAW_UPDATE_ASYNC
	)

	local results = { RAW_UPDATE_ASYNC(chest, key, f, ...) } :: { any }
	local success = results[1]

	if not success then
		local time_between_attempts = chest.time_between_attempts
		local max_attempts = chest.max_attempts
		local attempts = 1

		repeat
			task.wait(time_between_attempts)
			results = { RAW_UPDATE_ASYNC(chest, key, f, ...) } :: { any }
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
	end
	return success, unpack(results, 2)
end
