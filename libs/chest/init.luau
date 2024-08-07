
-- chest
-- a immutable session locked datastore wrapper
-- that should have everything u could ever want

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local retryer = require(ReplicatedStorage.packages.retryer)
local t = require(script.types)

export type MetadataAcceptable = t.MetadataAcceptable
export type JSONAcceptable = t.JSONAcceptable

export type GlobalGem<Value = JSONAcceptable, Metadata = MetadataAcceptable?> = t.GlobalGem<Value, Metadata>
export type Chest<Value = JSONAcceptable, Metadata = MetadataAcceptable?> = t.Chest<Value, Metadata>
export type Gem<Value = JSONAcceptable, Metadata = MetadataAcceptable?> = t.Gem<Value, Metadata>

local LIST_KEYS_ASYNC: typeof(DataStoreService:GetDataStore("").ListKeysAsync)
local UPDATE_ASYNC: typeof(DataStoreService:GetDataStore("").UpdateAsync)
local GET_ASYNC: typeof(DataStoreService:GetDataStore("").GetAsync)
local STR_FORMAT = string.format

local DATASTORE_OPTIONS = Instance.new("DataStoreOptions")
local GET_OPTIONS = Instance.new("DataStoreGetOptions")
local WEAK = table.freeze({ __mode = "v" })
local DATASTORE_CACHE_PERSISTANCE_TIME = 4
local DEFUALT_TIME_BETWEEN_ATTEMPTS = 3
local DEFUALT_MIN_SAVE_INTERVAL = 30
local DEFUALT_SAVE_INTERVAL = 180
local DEFUALT_MAX_ATTEMPTS = 5

local CHESTS = (setmetatable({}, WEAK) :: any) :: { t.Chest }
local EMPTY = table.freeze({})

DATASTORE_OPTIONS:SetExperimentalFeatures({ v2 = true })
GET_OPTIONS.UseCache = false

--------------------------------------------------------------------------------
-- error format strings
--------------------------------------------------------------------------------

local ERR_CANNOT_FIND_GEM = "[CHEST] cannot %s gem %s because it doesnt exist in chest %s"

--------------------------------------------------------------------------------
-- util funcs
--------------------------------------------------------------------------------

@native
local function REMOVE_CALLBACK<A...>(callbacks: { { (A...) -> () } }, info: { (A...) -> () })
	local index = table.find(callbacks, info)

	if index then
		if index ~= 1 then
			local len = #callbacks
			callbacks[index] = callbacks[len]
			callbacks[len] = nil
		else
			callbacks[1] = nil
		end
	end
end

@native
local function SPAWN_CALLBACKS<A...>(callbacks: { { (A...) -> () } }, ...: A...)
	for _, callback_info in callbacks do
		task.spawn(callback_info[1], ...)
	end
end

@native
local function IS_VERSION_UNSIGNEDINT(ver: number): boolean
	local sign = math.sign(ver)
	return ver % 1 == 0 and (sign == 1 or sign == 0)
end

@native
local function PACK_VARADIC(...: any): { any }
	return { ... }
end

local function RAW_UPDATE_ASYNC<Value, A...>(
	chest: Chest<Value>,
	key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	...: A...
): (boolean, Value, DataStoreKeyInfo)
	-- doing this to not get a type error
	local packed_args = PACK_VARADIC(...)
	
	return pcall(
		UPDATE_ASYNC, chest.datastore, key, 
		function(global_value: Value, global_keyinfo: DataStoreKeyInfo): (Value?, { number }?, t.SaveInfo?)
			local global_saveinfo = global_keyinfo:GetMetadata()
			local global_userids = global_keyinfo:GetUserIds()
			local new_value, new_save_info, new_userids = f(
				global_value, global_saveinfo or {} :: any, global_userids, unpack(packed_args :: any)
			)

			if new_save_info then
				return new_value, new_userids or global_userids, new_save_info or global_saveinfo
			else
				return nil
			end
		end
	)
end

local function PCALL_RAW_UPDATE_ASYNC<Value, A...>(
	chest: Chest<Value>,
	key: string,
	f: t.RawUpdateAsyncCallback<Value, A...>,
	...: A...
): (boolean, Value, DataStoreKeyInfo)


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

local function CALL_NO_YIELD<A..., R...>(f: (A...) -> R..., ...: A...): (boolean, R...)
	local rets
	local thread = task.spawn(function(...: A...)
		rets = { pcall(f, ...) }
	end, ...)

	if coroutine.status(thread) ~= "dead" then
		warn(debug.traceback(thread, "[CHEST] transform callbacks cannot yield"))
		return false
	else
		local success = rets[1]

		if success then
			return true, unpack(rets :: any, 2)
		else
			warn(debug.traceback(thread, "[CHEST] an error occured when calling a transform callback"))
			return false
		end
	end
end

-- merges a & b into one array, eliminating duplicate values
@native
local function MERGE_ARRAYS_UNIQUE_ONLY<V>(a: { V }, b: { V }): { V }
	local result_tbl = table.clone(a)

	for _, value in b do
		if not table.find(result_tbl, value) then
			table.insert(result_tbl, value)
		end
	end
	return result_tbl
end

@native
local function CREATE_KEYINFO(): t.KeyInfo
	return {
		threads_to_spawn_after_save = {},
		callbacks = table.freeze({
			on_close = {},
			on_save = {},
		}),
		is_saving = false,
		update_queue = {},
		metadata = EMPTY,
		saveinfo = EMPTY,
		userids = EMPTY,
		global = false,
		value = EMPTY,
		last_save = 0,
	} :: any
end

@native
local function CREATE_SAVEINFO(
	is_locked: boolean, 
	version: number,
	lock_uuid: string?,
	was_prev_update_global: boolean?,
	timestamp: number?
): t.SaveInfo
	return table.freeze({
		lock_uuid = lock_uuid or HttpService:GenerateGUID(false),
		was_prev_update_global = was_prev_update_global,
		timestamp = timestamp or os.time(),
		is_locked = is_locked,
		-- waiting for type functions to properly implement versioning,
		-- as currently the only good way to do it (atleast i think) cant have types
		version = version,
	})
end

@native
local function CLONE_BUFFER(buf: buffer): buffer
	local new_buffer = buffer.create(buffer.len(buf))
	buffer.copy(new_buffer, 0, buf)
	return new_buffer
end

@native
local function DEEP_FREEZE<T>(tbl: T & {}): T
	local tbl = tbl :: any

	for index, value in tbl do
		if type(value) == "table" then
			tbl[index] = DEEP_FREEZE(value :: any)
		end
	end
	return table.freeze(tbl) :: any
end

@native
local function DEEP_FROZEN_CLONE<T>(tbl: T & {}): T
    local clone = table.clone(tbl)
    
	for index, value in clone do
		if type(value) == "table" then
			clone[index] = DEEP_FROZEN_CLONE(value :: any)
		elseif type(value) == "buffer" then
			clone[index] = CLONE_BUFFER(value)
		end
	end
	return table.freeze(clone) :: any
end

@native
local function DEEPCLONE<T>(tbl: T & {}): T
    local clone = table.clone(tbl)
    
	for index, value in clone do
		if type(value) == "table" then
			clone[index] = DEEPCLONE(value :: any)
		elseif type(value) == "buffer" then
			clone[index] = CLONE_BUFFER(value)
		end
	end
	return clone :: any
end

@native
local function DEEP_ENSURE_UTF8<Value>(value: Value): boolean
	if type(value) == "string" and utf8.len(value) ~= #value then
		return false
	elseif type(value) == "table" then
		local tbl = value

		for key, value in tbl do
			if not (DEEP_ENSURE_UTF8(value) or DEEP_ENSURE_UTF8(key)) then
				return false
			end
		end
	end

	return true
end

@native
local function CLONE_VALUE<Value>(value: Value): Value
	return if type(value) == "table" then 
			DEEPCLONE(value) 
		elseif type(value) == "buffer" then 
			CLONE_BUFFER(value) :: any 
		else 
			value
end

@native
local function RECONCILE<T>(original: { [any]: any }, template: T & {}): T
	local tbl = table.clone(original)
	local template = template :: any

	for key, value: any in template :: {} do
		local tbl_key = tbl[key]

		if not tbl_key then
			tbl[key] = CLONE_VALUE(value)
		elseif type(tbl_key) == "table" and type(value) == "table" then
			tbl[key] = RECONCILE(tbl_key, value)
		end
	end

	return tbl :: any
end

local function CLONE_DEFAULT_VALUE<Value, Metadata>(chest: Chest<Value, Metadata>, key: string): Value
	local getter = chest.default_value_getter
	return if getter then getter(key) else CLONE_VALUE(chest.default_value :: any)
end

local function GET_KEYINFO_FOR_GEM(local_gem: t.Gem, error_action: string): t.KeyInfo
	local chest = local_gem.chest
	local name = local_gem.name
	local keyinfo = chest.local_keys[name]

	if keyinfo then
		return keyinfo :: any
	else
		error(STR_FORMAT(ERR_CANNOT_FIND_GEM, error_action, name, chest.name))
	end
end

-- in the following function i pray to god that deepcopying is fine
local function RUN_QUEUE_FOR_KEYINFO(keyinfo: t.KeyInfo): { thread }
	local threads_to_resume = keyinfo.threads_to_spawn_after_save
	local update_queue = keyinfo.update_queue
	local value = keyinfo.value

	for _, operation in update_queue do
		local args = operation.args
		local did_yield
		local new_value

		local cloned_value = CLONE_VALUE(value)

		if args then
			did_yield, new_value = CALL_NO_YIELD(
				operation.callback, cloned_value, unpack(args :: any)
			)
		else
			did_yield, new_value = CALL_NO_YIELD(
				operation.callback, cloned_value
			)
		end

		if new_value and not did_yield then
			keyinfo.value = new_value
			value = new_value
		end
	end

	table.clear(update_queue)
	return threads_to_resume
end

local function IS_EXPIRED(timestamp: number)
	return os.time() - timestamp >= 60
end

local function CAN_LOCK(saveinfo: t.SaveInfo): boolean
	local is_expired = IS_EXPIRED(saveinfo.timestamp or 0)
	local is_locked = saveinfo.is_locked

	return not is_locked -- Case 1: Not locked
		or (is_locked and is_expired) -- Case 2: Locked, expired
		or is_expired -- Case 3: expired
end

local function CAN_SAVE(saveinfo: t.SaveInfo, our_uuid: string): boolean
	local is_expired = IS_EXPIRED(saveinfo.timestamp)

	return saveinfo.lock_uuid == our_uuid -- Case 1: Locked by us
		or (saveinfo.is_locked and is_expired) -- Case 2: Locked, expired
		or is_expired -- Case 3: expired
end

local function MIGRATE(
	chest: Chest,
	saveinfo: t.SaveInfo,
	key: string,
	value: JSONAcceptable
): (t.LoadStatus, JSONAcceptable?)
	local save_version = saveinfo.version
	local migrations = chest.migrations
	local our_version = chest.version
	local new_value: any
	local success

	if not save_version then
		return "SUCCESS", CLONE_DEFAULT_VALUE(chest, key)
	elseif save_version > our_version then
		-- COULD NOT LOAD VALUE ERROR HERE
		return "SAVE VERSION TOO HIGH", nil
	end

	for nextver = save_version + 1, #migrations do
		local migrator = migrations[nextver]
		
		if not migrator then
			warn(`[CHEST] migration for version {nextver} does not exist cannot migrate`)
			return "MIGRATION NEXT VERSION NOT FOUND", nil
		end
		
		success, new_value = pcall(migrator, new_value)
		
		if not success then
			warn(`[CHEST] migration callback for version {nextver} errored\n\terror: {new_value}`)
			return "MIGRATION CALLBACK ERROR", nil
		end
	end

	return "SUCCESS", new_value
end

--------------------------------------------------------------------------------
-- base gem
--------------------------------------------------------------------------------

-- do when DataStore:GetVersionAtTimeAsync() is added
-- https://devforum.roblox.com/t/upcoming-changes-to-data-stores-versioning/3042258

local basegem_proto = {} :: t.BaseGemPrototype
(basegem_proto :: any).__index = basegem_proto 

do

	-- DO WHEN DataStore:GetVersionAtTimeAsync() is added
	basegem_proto.revert = function(gem: t.BaseGem, time: number, auto_migrate: boolean?): (boolean, string?)
		local gem: GlobalGem | Gem = gem :: any
		local chest = gem.chest

		error("[CHEST] method not implemented, waiting for DataStore:GetVersionAtTimeAsync() to be added")
	end :: any

	basegem_proto.datastore_version = function(gem: t.BaseGem, time: number): (boolean, string?)
		local gem: GlobalGem | Gem = gem :: any
		local chest = gem.chest

		error("[CHEST] method not implemented, waiting for DataStore:GetVersionAtTimeAsync() to be added")
	end :: any

	table.freeze(basegem_proto)
end

--------------------------------------------------------------------------------
-- gem
--------------------------------------------------------------------------------

local function save_local_keyinfo(chest: Chest, key: string, keyinfo: t.KeyInfo): (boolean, string?)
	keyinfo.is_saving = true
	RUN_QUEUE_FOR_KEYINFO(keyinfo)

	local threads_to_resume = keyinfo.threads_to_spawn_after_save
	local saveinfo = keyinfo.saveinfo
	local userids = keyinfo.userids
	local value = keyinfo.value

	local is_valid_utf8 = DEEP_ENSURE_UTF8(value)

	if not is_valid_utf8 then
		warn(`[CHEST] failed to save gem {key} in chest {chest.name} due to the value having invalid utf8`)
		return false, "invalid utf8"
	end

	SPAWN_CALLBACKS(keyinfo.callbacks.on_save, CLONE_VALUE(value))

	local success, posssible_error = RAW_UPDATE_ASYNC(
		chest, key, 
		function(
			global_value, global_saveinfo, global_userids, 
			our_value: JSONAcceptable, our_saveinfo: t.SaveInfo, our_userids: { number }?
		)
			if not CAN_SAVE(global_saveinfo, our_saveinfo.lock_uuid) then
				return nil
			end
			local global_update_info = global_saveinfo.global_update_info

			if global_update_info then
				if global_update_info.value_changed then
					our_value = RECONCILE(global_value :: any, our_value :: any)
				end

				if global_update_info.userids_changed and our_userids and global_userids then
					our_userids = MERGE_ARRAYS_UNIQUE_ONLY(our_userids, global_userids)
				end
			end

			our_saveinfo.timestamp = os.time()
			return our_value, our_saveinfo, our_userids
		end,
		value, saveinfo, userids
	)
	local error: string? = if not success then posssible_error :: any else nil

	if error then
		warn(`[CHEST] failed to save gem {key} in chest {chest.name}\n\tupdate-async-err: {error}`)
	end

	for _, thread in threads_to_resume do
		task.spawn(thread, success, error)
	end

	table.clear(threads_to_resume)
	keyinfo.last_save = os.time()
	keyinfo.is_saving = false
	return success, error
end

local gem = (setmetatable({}, basegem_proto) :: any) :: t.GemPrototype
(gem :: any).__index = gem 

do

	gem.transform = @native function(gem, transform, ...)
		local keyinfo = GET_KEYINFO_FOR_GEM(gem, "transform")

		table.insert(keyinfo.update_queue, table.freeze({
			args = table.freeze({ ... }),
			callback = transform,
		}))
		return gem
	end
	
	gem.on_close = @native function(gem, f)
		local keyinfo = GET_KEYINFO_FOR_GEM(gem, "add on_close callback to")
		local on_close_callbacks = keyinfo.callbacks.on_close
		local callback_info = table.freeze({ f })
	
		table.insert(on_close_callbacks, callback_info)
		return function()
			REMOVE_CALLBACK(on_close_callbacks, callback_info)
		end
	end
	
	gem.on_save = @native function(gem, f)
		local keyinfo = GET_KEYINFO_FOR_GEM(gem, "add on_save callback to")
		local on_save_callbacks = keyinfo.callbacks.on_save
		local callback_info = table.freeze({ f })
	
		table.insert(on_save_callbacks, callback_info)
		return function()
			REMOVE_CALLBACK(on_save_callbacks, callback_info)
		end
	end

	gem.detach_user = @native function(gem, userid)
		local keyinfo = GET_KEYINFO_FOR_GEM(gem, "detach userid from")
		local userids = keyinfo.userids
		local index = table.find(userids, userid)

		if index then
			table.remove(userids, index)
		end
		return gem
	end

	gem.attach_user = @native function(gem, userid)
		local keyinfo = GET_KEYINFO_FOR_GEM(gem, "attach userid to")
		table.insert(keyinfo.userids, userid)
		return gem
	end
	
	gem.users = @native function(gem)
		return table.clone(
			GET_KEYINFO_FOR_GEM(gem, "get userids for").userids
		)
	end
	
	gem.value = @native function(gem)
		return CLONE_VALUE(
			GET_KEYINFO_FOR_GEM(gem, "get value for").value
		)
	end

	gem.save = function(gem: Gem): (boolean, string?)
		local keyinfo = GET_KEYINFO_FOR_GEM(gem, "save")

		if keyinfo.is_saving then
			table.insert(keyinfo.threads_to_spawn_after_save, coroutine.running())
			return coroutine.yield()
		else
			return save_local_keyinfo(gem.chest, gem.name, keyinfo)
		end
	end :: any

	table.freeze(gem)
end

local function create_gem(chest: Chest, name: string, version: number): Gem
	return table.freeze(setmetatable({
		version = version,
		chest = chest,
		name = name,
	}, gem)) :: any
end

--------------------------------------------------------------------------------
-- global gem
--------------------------------------------------------------------------------

local globalgem = (setmetatable({}, basegem_proto) :: any) :: t.GlobalGemPrototype
(globalgem :: any).__index = globalgem

do

	local NOOP = function() end

	globalgem.transform_async = function(gem, transform, ...): (t.LoadStatus, string?)
		local status: t.LoadStatus = "SUCCESS"
		local chest = gem.chest
		local name = gem.name

		local success, possible_error = RAW_UPDATE_ASYNC(chest, name, function(
			global_value, global_saveinfo, global_userids, 
			chest: Chest, name: string, ...
		)
			local migrated_value

			status, migrated_value = MIGRATE(
				chest, global_saveinfo, name, global_value
			)

			if status == "SUCCESS" then
				local new_value = transform(migrated_value, ...)

				if new_value then
					local old_update_info = global_saveinfo.global_update_info
					local global_update_info = {
						userids_changed = if old_update_info then old_update_info.userids_changed else nil,
						value_changed = true,
					}
	
					global_saveinfo.global_update_info = global_update_info
					return new_value, global_saveinfo, global_userids
				end
			end

			return nil
		end, chest, name, ...)

		if success then
			return status, nil
		else
			return status, possible_error :: any
		end
	end :: any

	local attach_user_updater: t.RawUpdateAsyncCallback<JSONAcceptable, number> = function(
		global_value, global_saveinfo, global_userids, userid: number
	)
		local old_update_info = global_saveinfo.global_update_info
		local userids: { number }

		if global_userids then
			table.insert(global_userids, userid)
			userids = global_userids
		else
			userids = { userid }
		end

		local old_update_info = global_saveinfo.global_update_info
		local global_update_info = {
			value_changed = if old_update_info then old_update_info.value_changed else nil,
			userids_changed = true,
		}

		global_saveinfo.global_update_info = global_update_info
		return global_value, global_saveinfo, global_userids
	end

	globalgem.attach_user = function(gem, userid): (boolean, string?)
		local chest = gem.chest
		local success, value = RAW_UPDATE_ASYNC(
			gem.chest, gem.name, attach_user_updater, userid
		)

		if success then
			return true, nil
		else
			return false, value :: any
		end
	end :: any

	local detach_user_updater: t.RawUpdateAsyncCallback<JSONAcceptable, number> = function(
		global_value, global_saveinfo, global_userids, userid: number
	)
		if global_userids then
			local old_update_info = global_saveinfo.global_update_info
			local index = table.find(global_userids, userid)
		
			if index then
				table.remove(global_userids, index)
			end

			local global_update_info = {
				value_changed = if old_update_info then old_update_info.value_changed else nil,
				userids_changed = true,
			}

			global_saveinfo.global_update_info = global_update_info
			return global_value, global_saveinfo, global_userids
		end
	
		return nil
	end

	globalgem.detach_user = function(gem, userid): (boolean, string?)
		local chest = gem.chest
		local success, value = RAW_UPDATE_ASYNC(
			gem.chest, gem.name, detach_user_updater, userid
		)

		if success then
			return true, nil
		else
			return false, value :: any
		end
	end :: any
	
	globalgem.users = function(gem): (boolean, { number }? | string)
		local chest = gem.chest
		local success, value, ds_keyinfo = RAW_UPDATE_ASYNC(gem.chest, gem.name, NOOP)

		if success then
			return true, ds_keyinfo:GetUserIds()
		else
			return false, value
		end
	end :: any
	
	globalgem.value = function(gem): (boolean, JSONAcceptable | string)
		local chest = gem.chest
		local name = gem.name
		local success, value, ds_keyinfo = RAW_UPDATE_ASYNC(gem.chest, name, NOOP)

		if success then
			return true, value or CLONE_DEFAULT_VALUE(chest, name)
		else
			return false, value
		end
	end :: any

	table.freeze(globalgem)
end

local function create_global_gem(chest: Chest, name: string, version: number): GlobalGem
	return table.freeze(setmetatable({
		version = version,
		chest = chest,
		name = name,
	}, globalgem)) :: any
end

--------------------------------------------------------------------------------
-- chest
--------------------------------------------------------------------------------

local chestproto = {} :: t.ChestPrototype
(chestproto :: any).__index = chestproto 

do

	chestproto.view = function(chest: Chest, key: string): (boolean, JSONAcceptable | string, { number }?)
		local success, value, keyinfo = retryer.delay(
			chest.time_between_attempts, chest.max_attempts, GET_ASYNC :: any, chest.datastore, 
			key, GET_OPTIONS
		)
	
		if success then
			return true, value or CLONE_DEFAULT_VALUE(chest, key), keyinfo:GetUserIds()
		else
			warn(`[CHEST] an error occured while trying to view data asynchronously for key {key} in chest {chest.name}\n\tdatastore-err: {value}`)
			return false, value, nil
		end
	end :: any

	chestproto.locknload = function(chest: Chest, key: string): (boolean, Gem?)
		local new_keyinfo = CREATE_KEYINFO()
		local status: t.LoadStatus
		local did_lock = false
	
		local success, error = RETRY_RAW_UPDATE_ASYNC(
			chest, key, function(global_value, global_saveinfo, global_userids)
				if not CAN_LOCK(global_saveinfo) then
					return nil
				end

				local migrated_value: any

				status, migrated_value = MIGRATE(
					chest, global_saveinfo, key, global_value
				)

				if status ~= "SUCCESS" then
					return nil
				end

				local new_saveinfo = CREATE_SAVEINFO(true, chest.version)
				local new_userids = global_userids or {}
	
				new_keyinfo.userids = new_userids
				new_keyinfo.saveinfo = new_saveinfo
				new_keyinfo.value = migrated_value
				new_keyinfo.userids = new_userids
				did_lock = true
	
				return migrated_value, new_saveinfo, new_userids
			end
		)
	
		if success and did_lock then
			new_keyinfo.last_save = os.time()
			chest.local_keys[key] = new_keyinfo
			return true, create_gem(chest, key, chest.version)
		else
			warn(`[CHEST] an error occured while trying to load data for key {key} in chest {chest.name}\n\tdatastore-err: {error}`)
			return false, nil
		end
	end :: any

	chestproto.load = function(chest: Chest, key: string): (boolean, GlobalGem?)
	
	end :: any

	chestproto.steal = function(chest: Chest, key: string): (boolean, Gem?)
		local new_keyinfo = CREATE_KEYINFO()

		local success, error = RAW_UPDATE_ASYNC(
			chest, key, function(global_value, global_saveinfo, global_userids, new_keyinfo: t.KeyInfo)
				local saveinfo = CREATE_SAVEINFO(global_value, true)
	
				new_keyinfo.metadata = global_metadata
				new_keyinfo.userids = global_userids
				new_keyinfo.value = global_value
				new_keyinfo.saveinfo = saveinfo
				return saveinfo, global_userids, global_metadata
			end,
			new_keyinfo
		)
	
		if not success then
			warn(`[CHEST] an error occured while trying to steal lock for key {key} in chest {chest.name}\n\tdatastore-err: {error}`)
			return false, nil
		else
			new_keyinfo.last_save = os.time()
			chest.local_keys[key] = new_keyinfo
			return true, create_gem(chest, key, chest.version)
		end
	end :: any

	chestproto.lock = function(chest: Chest, globalgem: GlobalGem): (boolean, Gem?)
		local global_keys = chest.global_keys
		local key = globalgem.name
		local new_keyinfo = CREATE_KEYINFO()
		local keyinfo = global_keys[key]
		local did_lock = { false }

		if not keyinfo then
			return false, nil
		end

		keyinfo.is_saving = true
	
		local success, error = RAW_UPDATE_ASYNC(
			chest, 
			key, 
			function(
				global_saveinfo, global_userids, global_metadata, 
				did_lock: { boolean }, keyinfo: t.GlobalKeyInfo, 
				key: string, chest: Chest, new_keyinfo: t.LocalKeyInfo
			)
				local global_value = global_saveinfo.previous_value or CLONE_DEFAULT_VALUE(chest, key)
				local global_timestamp = global_saveinfo.timestamp or 0
				local is_expired = os.time() - global_timestamp >= 60
				local is_locked = global_saveinfo.is_locked
			
				local should_lock = not is_locked -- Case 1: Not locked
					or (is_locked and is_expired) -- Case 2: Locked, expired
					or is_expired -- Case 3: expired
			
				if should_lock then
					local new_saveinfo = CREATE_SAVEINFO(global_value, true)
					local keyinfo: LocalKeyInfo = keyinfo :: any

					new_keyinfo.metadata = global_metadata
					new_keyinfo.userids = global_userids
					new_keyinfo.saveinfo = new_saveinfo
					new_keyinfo.value = global_value
					did_lock[1] = true
	
					return new_saveinfo, global_userids, global_metadata
				else
					return nil
				end
			end,
			did_lock, keyinfo, key, chest, new_keyinfo
		)

		keyinfo.is_saving = false

		if success and did_lock[1] then
			global_keys[key] = nil
			new_keyinfo.last_save = os.time()
			chest.local_keys[key] = new_keyinfo :: any

			return true, create_gem(chest, key)
		elseif not success then
			warn(`[CHEST] an error occured while trying to load data for key {key} in chest {chest.name}\n\tdatastore-err: {error}`)
			return false, nil
		else
			warn(`[CHEST] an error occured while trying to load data for key {key} in chest {chest.name}\n\tdatastore-err: {error}`)
			return false, nil
		end
	end :: any

	function chestproto.unload(chest, gem)
		local keyname = gem.name
		local local_keys = chest.local_keys
		local keyinfo = local_keys[keyname]
	
		if not keyinfo then
			warn(`[CHEST] cannot unload gem {keyname} as it is not loaded in this server`)
			return
		end
	 
		task.defer(function(keyinfo: t.KeyInfo, keyname: string)
			local success, error = RAW_UPDATE_ASYNC(
				chest, keyname, function(
					global_saveinfo, _, _, 
					our_saveinfo: t.SaveInfo, 
					our_userids: { number }?, 
					our_metadata: MetadataAcceptable?
				)
					if global_saveinfo.lock_uuid == our_saveinfo.lock_uuid then
						return CREATE_SAVEINFO(our_saveinfo.value, false, ""), our_userids, our_metadata
					else
						return nil
					end
				end, 
				keyinfo.saveinfo, keyinfo.userids, keyinfo.metadata
			)
	
			if not success then
				warn(`[CHEST] an error occured while trying unlock data for key {keyname} in chest {chest.name}\n\tdatastore-err: {error}`)
			end
		end, keyinfo, keyname)
	
		local_keys[keyname] = nil
	end

	@native
	function chestproto.on_close(chest, f)
		local on_close_callbacks = chest.callbacks.on_close
		local callback_info = table.freeze({ f })
	
		table.insert(on_close_callbacks, callback_info)
		return function()
			REMOVE_CALLBACK(on_close_callbacks, callback_info)
		end
	end

	@native
	function chestproto.on_save(chest, f)
		local on_close_callbacks = chest.callbacks.on_save
		local callback_info = table.freeze({ f })
	
		table.insert(on_close_callbacks, callback_info)
		return function()
			REMOVE_CALLBACK(on_close_callbacks, callback_info)
		end
	end

	table.freeze(chestproto)
end

local function create_chest<Value, Metadata>(
	name: string,
	scope: string,
	info: t.ChestInfo<Value>
): Chest<Value, Metadata>
	local datastore = DataStoreService:GetDataStore(name, scope, DATASTORE_OPTIONS)
	local chest = setmetatable({
		time_between_attempts = info.time_between_attempts or DEFUALT_TIME_BETWEEN_ATTEMPTS,
		min_save_interval = info.min_save_interval or DEFUALT_MIN_SAVE_INTERVAL,
		save_interval = info.save_interval or DEFUALT_SAVE_INTERVAL,
		max_attempts = info.max_attempts or DEFUALT_MAX_ATTEMPTS,
		defualt_value_getter = info.default_value_getter,
		global_gems = setmetatable({}, WEAK) :: any,
		default_value = info.default_value :: any,
		retry_exponent = info.retry_exponent or 0,
		datastore = datastore,
		migrations = {},
		local_keys = {},
		scope = scope,
		version = 0,
		name = name,

		callbacks = table.freeze({
			on_close = {},
			on_save = {},
		}),
	}, chest)

	UPDATE_ASYNC = datastore.UpdateAsync
	GET_ASYNC = datastore.GetAsync

	table.insert(CHESTS, chest)
	-- the any cast here is needed as otherwise the solver complains abt the chest type being too complex to typecheck
	return chest :: any
end

do

	RunService.PostSimulation:Connect(function()
		for _, chest in CHESTS do
			local min_save_interval = chest.min_save_interval
			local save_interval = chest.save_interval
		
			for key, keyinfo in chest.local_keys do
				local last_save = keyinfo.last_save
		
				if not keyinfo.modified or last_save <= save_interval then
					continue
				elseif os.time() - last_save <= min_save_interval then
					continue
				end
		
				task.spawn(save_local_keyinfo, chest :: any, key, keyinfo)
			end
		end
	end)

	game:BindToClose(function()
		for _, chest in CHESTS do
			
		end
	end)

end

return create_chest