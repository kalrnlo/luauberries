--!native
--!strict

-- retryer
-- utility module for retrying functions easily
-- @kalrnlo
-- 23/05/2024

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

-- they both have the same type but luau infers it as (number?) -> number | (number?) -> number
-- if the local itself isnt annotated
local WAIT_FN: (number?) -> number = if task then task.wait elseif wait then wait else WAIT

local function retry_with_delay<A..., R...>(delay: number, max_attempts: number, f: (A...) -> (R...), ...: A...): (boolean, R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not results[1] then
		WAIT_FN(delay)
		local attempts = 1

		repeat
			results = { pcall(f, ...) }
			success = results[1]
			attempts += 1
			WAIT_FN(delay)
		until results[1] or attempts == max_attempts
	end
	return success, unpack(results, 2)
end

-- if self isnt defined as a generic the other generics dont get infered correctly
local function retry<S, A..., R...>(self: S, max_attempts: number, f: (A...) -> (R...), ...: A...): (boolean, R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not success then
		local attempts = 1

		repeat
			results = { pcall(f, ...) }
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
	end
	return success, unpack(results, 2)
end

local function infretry_with_delay<A..., R...>(delay: number, f: (A...) -> (R...), ...: A...): (boolean, R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not success then
		WAIT_FN(delay)

		repeat
			results = { pcall(f, ...) }
			success = results[1]
			WAIT_FN(delay)
		until success
	end
	return success, unpack(results, 2)
end

local function infretry<S, A..., R...>(self: S, f: (A...) -> (R...), ...: A...): (boolean, R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not success then
		WAIT_FN()

		repeat
			results = { pcall(f, ...) }
			success = results[1]
			WAIT_FN()
		until success
	end
	return success, unpack(results, 2)
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
	inf = table.freeze(setmetatable(inf_tbl :: any, table.freeze(inf_mt))),
	delay = retry_with_delay,
}

return table.freeze(setmetatable(tbl :: any, table.freeze(mt))) :: typeof(setmetatable({
	inf = setmetatable({ delay = infretry_with_delay }, { __call = infretry }),
	delay = retry_with_delay,
}, { __call = retry }))
