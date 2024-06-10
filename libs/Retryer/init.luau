--!native
--!strict

-- retryer
-- utility module for retrying functions easily
-- @kalrnlo
-- 23/05/2024

local pack = table.pack

local function WAIT(seconds: number?): number
	local start_time = os.clock()
	local end_time = start_time + (seconds or .5)
	local clock_time: number

	repeat
		math.sqrt(5)
		clock_time = os.clock()
	until clock_time >= end_time
	return clock_time - start_time
end

-- they both have the same type but luau infers it as (number?) -> number | (number?) -> number
-- if the local itself isnt annotated
local WAIT_FN: (number?) -> number = if task then task.wait else WAIT

local function retry_with_delay<T..., A...>(delay: number, max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = pack(pcall(callback, ...))

	if not results[1] then
		WAIT_FN(delay)
		local attempts = 1

		repeat
			results = pack(pcall(callback, ...))
			attempts += 1
			WAIT_FN(delay)
		until results[1] or attempts == max_attempts
	end
	return table.unpack(results) :: any
end

-- if self isnt defined as a generic the other generics dont get infered correctly
local function retry<S, T..., A...>(self: S, max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = pack(pcall(callback, ...))

	if not results[1] then
		local attempts = 1

		repeat
			results = pack(pcall(callback, ...))
			attempts += 1
		until results[1] or attempts == max_attempts
	end
	return table.unpack(results) :: any
end

local function infretry_with_delay<T..., A...>(delay: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = pack(pcall(callback, ...))

	if not results[1] then
		WAIT_FN(delay)

		repeat
			results = pack(pcall(callback, ...))
			WAIT_FN(delay)
		until results[1]
	end
	return table.unpack(results) :: any
end

local function infretry<S, T..., A...>(self: S, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = pack(pcall(callback, ...))

	if not results[1] then
                WAIT_FN()

		repeat
			results = pack(pcall(callback, ...))
                        WAIT_FN()
		until results[1]
	end
	return table.unpack(results) :: any
end

local inf_tbl = {
	delay = infretry_with_delay,
}
local inf_mt = {
	__call = infretry
}
inf_mt.__index = inf_mt

local mt = {
	__call = retry,
}
mt.__index = mt
local tbl = {
	inf = table.freeze(setmetatable(inf_tbl, inf_mt)) :: typeof(setmetatable({} :: typeof(inf_tbl), {} :: typeof(inf_mt))),
	delay = retry_with_delay,
}

local exports = table.freeze(setmetatable(tbl, mt)) :: typeof(setmetatable(tbl, mt))

return exports
