--!native

-- retryer
-- utility module for retrying functions easily

local function WAIT(seconds: number?): number
	local start_time = os.clock()
	local end_time = start_time + (seconds or 1)
	local clock_time: number

	repeat
		clock_time = os.clock()
	until clock_time >= end_time
	return clock_time - start_time
end

-- in roblox, scripts if theyre too fast can exaust execution time 
-- (its so empty while true do loops dont infintly run)
-- so we use this for the retry functions without any delays so athey dont have errors in roblox
local WAIT_FN_SO_SCRIPT_DOESNT_EXAUST_EXECUTION_TIME: () -> () = if task then task.wait else function() end

-- they both have the same type but luau infers it as (number?) -> number | (number?) -> number
-- if the local itself isnt annotated
local WAIT_FN: (number?) -> number = if task then 
		task.wait 
	elseif string.find(_VERSION, "Lune") then 
		(require)("@lune/task").wait 
	elseif wait then 
		wait 
	else 
		WAIT

local function retry_with_exponent<A..., R...>(
	delay: number,
	delay_exponent: number,
	max_attempts: number,
	f: (A...) -> (R...), ...: A...
): (boolean, R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not results[1] then
		local attempts = 1

		repeat
			WAIT_FN(delay + (delay_exponent ^ attempts))
			results = { pcall(f, ...) }
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
	end
	return success, unpack(results, 2)
end

local function retry_with_delay<A..., R...>(delay: number, max_attempts: number, f: (A...) -> (R...), ...: A...): (boolean, R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not results[1] then
		local attempts = 1

		repeat
			WAIT_FN(delay)
			results = { pcall(f, ...) }
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
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
			WAIT_FN_SO_SCRIPT_DOESNT_EXAUST_EXECUTION_TIME()
			results = { pcall(f, ...) }
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
	end
	return success, unpack(results, 2)
end

local function infretry_with_exponent<A..., R...>(
	delay: number,
	delay_exponent: number,
	f: (A...) -> (R...), ...: A...
): (R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not success then
		local attempts = 1

		repeat
			WAIT_FN(delay + (delay_exponent ^ attempts))
			results = { pcall(f, ...) }
			success = results[1]
			attempts += 1
		until success
	end
	return unpack(results, 2)
end

local function infretry_with_delay<A..., R...>(delay: number, f: (A...) -> (R...), ...: A...): (R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not success then
		repeat
			WAIT_FN(delay)
			results = { pcall(f, ...) }
			success = results[1]
		until success
	end
	return unpack(results, 2)
end

local function infretry<A..., R...>(f: (A...) -> (R...), ...: A...): (R...)
	local results: any = { pcall(f, ...) }
	local success = results[1]

	if not success then
		repeat
			WAIT_FN_SO_SCRIPT_DOESNT_EXAUST_EXECUTION_TIME()
			results = { pcall(f, ...) }
			success = results[1]
		until success
	end
	return unpack(results, 2)
end

local mt = {
	__call = retry,
}
mt.__index = mt

local tbl = {
	infexp = infretry_with_exponent,
	infdelay = infretry_with_delay,
	exp = retry_with_exponent,
	delay = retry_with_delay,
	inf = infretry,
}

return table.freeze(setmetatable(tbl :: any, table.freeze(mt))) :: typeof(setmetatable({
	infexp = infretry_with_exponent,
	infdelay = infretry_with_delay,
	exp = retry_with_exponent,
	delay = retry_with_delay,
	inf = infretry,
}, { __call = retry }))
