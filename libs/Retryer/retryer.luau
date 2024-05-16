--!native
--!strict

-- retryer
-- utility module for retrying functions easily
-- @kalrnlo
-- 10/05/2024

local metaize = require(script.Parent.metaize)

local function WAIT(seconds: number?): number
	local start_time = os.clock()
	local end_time = start_time + (seconds or 1)
	local clock_time: number

	repeat
		math.sqrt(5)
		clock_time = os.clock()
	until clock_time >= end_time
	return clock_time - start_time
end

local WAIT_FN:(number?) -> number = if task then task.wait else WAIT

local function retry_with_delay<T..., A...>(delay: number, max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = table.pack(pcall(callback, ...))

	if not results[1] then
		WAIT_FN(delay)
		local attempts = 1

		repeat
			results = table.pack(pcall(callback, ...))
			attempts += 1
			WAIT_FN(delay)
		until results[1] or attempts == max_attempts
	end
	return table.unpack(results) :: any
end

local function retry_call<T..., A...>(self: unknown, max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = table.pack(pcall(callback, ...))

	if not results[1] then
		local attempts = 1

		repeat
			results = table.pack(pcall(callback, ...))
			attempts += 1
		until results[1] or attempts == max_attempts
	end
	return table.unpack(results) :: any
end

-- temp until new luau typechecker fixes the issues with using __call with a function that has generics
local function retry<T..., A...>(max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = table.pack(pcall(callback, ...))

	if not results[1] then
		local attempts = 1

		repeat
			results = table.pack(pcall(callback, ...))
			attempts += 1
		until results[1] or attempts == max_attempts
	end
	return table.unpack(results) :: any
end

local function infretry_with_delay<T..., A...>(delay: number, max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = table.pack(pcall(callback, ...))

	if not results[1] then
		WAIT_FN(delay)

		repeat
			results = table.pack(pcall(callback, ...))
			WAIT_FN(delay)
		until results[1]
	end
	return table.unpack(results) :: any
end

local function infretry_call<T..., A...>(self: unknown, max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = table.pack(pcall(callback, ...))

	if not results[1] then
		repeat
			results = table.pack(pcall(callback, ...))
		until results[1]
	end
	return table.unpack(results) :: any
end

-- temp until new luau typechecker fixes the issues with using __call with a function that has generics
local function infretry<T..., A...>(callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = table.pack(pcall(callback, ...))

	if not results[1] then
		repeat
			results = table.pack(pcall(callback, ...))
		until results[1]
	end
	return table.unpack(results) :: any
end

local inf_tbl = {
	delay = infretry_with_delay,
	create = infretry
}
local inf_mt = metaize {
	__call = infretry_call
}

local mt = metaize {
	__call = retry_call,
}
local tbl = {
	inf = table.freeze(setmetatable(inf_tbl, inf_mt)) :: typeof(setmetatable({} :: typeof(inf_tbl), {} :: typeof(inf_mt))),
	delay = retry_with_delay,
	create = retry,
}

local exports = table.freeze(setmetatable(tbl, mt)) :: typeof(setmetatable({} :: typeof(tbl), {} :: typeof(mt)))

return exports
