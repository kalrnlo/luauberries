--!native

-- retryer
-- utility module for retrying functions easily
-- @kalrnlo
-- 07/05/2024

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
	local results = { pcall(callback, ...) }

	if not results[1] then
		WAIT_FN(delay)
		local attempts = 1

		repeat
			results = { pcall(callback, ...) }
			attempts += 1
			WAIT_FN(delay)
		until results[1] or attempts == max_attempts
	end
	return table.unpack(results) :: any
end

local function retry<T..., A...>(self: unknown, max_attempts: number, callback: (T...) -> (A...), ...: T...): (boolean, A...)
	local results = { pcall(callback, ...) }

	if not results[1] then
		local attempts = 1

		repeat
			results = { pcall(callback, ...) }
			attempts += 1
		until results[1] or attempts == max_attempts
	end
	return table.unpack(results) :: any
end

local mt =  {
	__call = retry,
}
mt.__index = mt
table.freeze(mt)

local exports = setmetatable(table.freeze({
	delay = retry_with_delay
}), mt) :: typeof(setmetatable({} :: { delay: typeof(retry_with_delay) }, {} :: { __call: typeof(retry)}))

return exports
