
-- raw update
-- util for wrapping update async so its easier to use

local retryer = require("libs/retryer")
local t = require("types")

type RawUpdate = typeof(setmetatable({} :: { retry: RawUpdateFn }, {} :: RawUpdatePrototype))

type RawUpdateFn = <Value, A...>(
	chest: t.Chest<Value>, key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	A...
) -> (boolean, Value, DataStoreKeyInfo)

type RawUpdatePrototype = {
	__call: <S, Value, A...>(
		self: S, chest: t.Chest<Value>, key: string,
		f: t.RawUpdateAsyncCallback<Value, A...>, A...
	) -> (boolean, Value, DataStoreKeyInfo)
}

local raw_update = {} :: { retry: RawUpdateFn }
local raw_update_mt = {} :: RawUpdatePrototype

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

function raw_update_mt.__call(self, chest, key, f, ...)
	-- type error: generic subtype escaping scope occurs if i dont typecast chest
	return pcall(RAW_UPDATE_ASYNC, chest :: any, key, f, ...)
end

function raw_update.retry(chest, key, f, ...)
	-- same type error here sigh..
	return retryer.exp(
		chest.time_between_attempts, chest.retry_exponent, 
		chest.max_attempts, RAW_UPDATE_ASYNC, chest :: any, 
		key, f, ...
	)
end

table.freeze(setmetatable(raw_update, table.freeze(raw_update_mt)))
return (raw_update :: any) :: RawUpdate