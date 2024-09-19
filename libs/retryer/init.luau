--!native

-- retryer
-- utility module for retrying functions easily

local cross = require("../cross/init")

type Results = { 
	n: number,
	[number]: any
}

local PACK = table.pack
local WAIT = cross.wait

local retryer_mt = {}

-- if self isnt defined as a generic the other generics dont get infered correctly
function retryer_mt.__call<S, A..., R...>(
	self: S,
	max_attempts: number,
	f: (A...) -> (R...),
	...: A...
): (boolean, R...)
	local results: Results = PACK(pcall(f, ...))
	local success = results[1]

	if not success then
		local attempts = 1

		repeat
			WAIT()
			results = PACK(pcall(f, ...))
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
	end
	return success, unpack(results, 2, results.n)
end

local retryer = setmetatable({}, table.freeze(retryer_mt))

function retryer.infdelay<A..., R...>(delay: number, f: (A...) -> (R...), ...: A...): R...
	local results: Results = PACK(pcall(f, ...))
	local success = results[1]

	if not success then
		repeat
			WAIT(delay)
			results = PACK(pcall(f, ...))
			success = results[1]
		until success
	end
	return unpack(results, 2, results.n)	
end

function retryer.infexp<A..., R...>(
	delay: number,
	delay_exponent: number,
	f: (A...) -> (R...), 
	...: A...
): R...
	local results: Results = PACK(pcall(f, ...))
	local success = results[1]

	if not success then
		local attempts = 1

		repeat
			WAIT(delay + (delay_exponent ^ attempts))
			results = PACK(pcall(f, ...))
			success = results[1]
			attempts += 1
		until success
	end
	return unpack(results, 2, results.n)	
end

function retryer.delay<A..., R...>(
	delay: number,
	max_attempts: number,
	f: (A...) -> (R...), 
	...: A...
): (boolean, R...)
	local results: Results = PACK(pcall(f, ...))
	local success = results[1]

	if not results[1] then
		local attempts = 1

		repeat
			WAIT(delay)
			results = PACK(pcall(f, ...))
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
	end
	return success, unpack(results, 2, results.n)	
end

function retryer.exp<A..., R...>(
	delay: number,
	delay_exponent: number,
	max_attempts: number,
	f: (A...) -> (R...), ...: A...
): (boolean, R...)
	local results: Results = PACK(pcall(f, ...))
	local success = results[1]

	if not results[1] then
		local attempts = 1

		repeat
			WAIT(delay + (delay_exponent ^ attempts))
			results = PACK(pcall(f, ...))
			success = results[1]
			attempts += 1
		until success or attempts == max_attempts
	end
	return success, unpack(results, 2, results.n)	
end

function retryer.inf<A..., R...>(f: (A...) -> (R...), ...: A...): R...
	local results: Results = PACK(pcall(f, ...))
	local success = results[1]

	if not success then
		repeat
			WAIT()
			results = PACK(pcall(f, ...))
			success = results[1]
		until success
	end
	return unpack(results, 2, results.n)	
end

return table.freeze(retryer)