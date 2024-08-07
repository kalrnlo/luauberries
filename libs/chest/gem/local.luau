
-- local gem
-- class for keys that the server has ownership over

local DEEP_ENSURE_UTF8 = require("../deep_ensure_utf8")
local RAW_UPDATE = require("../raw_update")
local GET_KEYINFO = require("get_keyinfo")
local CALLBACKS = require("../callbacks")
local DATA_OPS = require("../data_ops")
local SESSION = require("../session")
local cross = require("libs/cross")
local t = require("../types")
local base = require("base")

local gem = (setmetatable({}, base) :: any) :: t.GemPrototype
(gem :: any).__index = gem

local function CALL_NO_YIELD<A..., R...>(f: (A...) -> R..., ...: A...): (boolean, R...)
	local rets
	local thread = cross.spawn(function(...: A...)
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

local function RUN_QUEUE_FOR_KEYINFO(keyinfo: t.KeyInfo): { thread }
	local threads_to_resume = keyinfo.threads_to_spawn_after_save
	local update_queue = keyinfo.update_queue
	local value = keyinfo.value

	for _, operation in update_queue do
		local args = operation.args
		local did_yield
		local new_value

		local cloned_value = DATA_OPS.CLONE_VAL(value)

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

local function save_local_keyinfo(chest: t.Chest, key: string, keyinfo: t.KeyInfo): (boolean, string?)
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

	CALLBACKS.SPAWN(keyinfo.callbacks.on_save, DATA_OPS.CLONE_VAL(value))

	local success, posssible_error = RAW_UPDATE.SAFE(
		chest, key, 
		function(
			global_value, global_saveinfo, global_userids, 
			our_value: t.JSONAcceptable, our_saveinfo: t.SaveInfo, our_userids: { number }
		)
			if not SESSION.CAN_SAVE(global_saveinfo, our_saveinfo.lock_uuid) then
				return nil
			end
			local global_update_info = global_saveinfo.global_update_info

			if global_update_info then
				if global_update_info.value_changed then
					our_value = DATA_OPS.RECONCILE(global_value :: any, our_value :: any)
				end

				if global_update_info.userids_changed and global_userids then
					our_userids = DATA_OPS.MERGE_ARRAYS_UNIQUE_ONLY(our_userids, global_userids)
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

function gem.transform(gem, transform, ...)
	local keyinfo = GET_KEYINFO(gem, "transform")

	table.insert(keyinfo.update_queue, table.freeze({
		args = table.freeze({ ... }),
		callback = transform,
	}))
	return gem
end

function gem.on_close(gem, f)
	local keyinfo = GET_KEYINFO(gem, "add on_close callback to")
	return CALLBACKS.CONNECTION(keyinfo.callbacks.on_close, f)
end

function gem.on_save(gem, f)
	local keyinfo = GET_KEYINFO(gem, "add on_save callback to")
	return CALLBACKS.CONNECTION(keyinfo.callbacks.on_save, f)
end

function gem.detach_user(gem, userid)
	local keyinfo = GET_KEYINFO(gem, "detach userid from")
	local userids = keyinfo.userids
	local index = table.find(userids, userid)

	if index then
		table.remove(userids, index)
	end
	return gem
end

function gem.attach_user(gem, userid)
	local keyinfo = GET_KEYINFO(gem, "attach userid to")
	table.insert(keyinfo.userids, userid)
	return gem
end

function gem.users(gem)
	return table.clone(
		GET_KEYINFO(gem, "get userids for").userids
	)
end

function gem.value(gem)
	return DATA_OPS.CLONE_VAL(
		GET_KEYINFO(gem, "get value for").value
	)
end

gem.save = function(gem: t.Gem): (boolean, string?)
	local keyinfo = GET_KEYINFO(gem, "save")

	if keyinfo.is_saving then
		table.insert(keyinfo.threads_to_spawn_after_save, coroutine.running())
		return coroutine.yield()
	else
		return save_local_keyinfo(gem.chest, gem.name, keyinfo)
	end
end :: any

local function create(chest: t.Chest, name: string, version: number): t.Gem
	return table.freeze(setmetatable({
		version = version,
		chest = chest,
		name = name,
	}, gem)) :: any
end

return create