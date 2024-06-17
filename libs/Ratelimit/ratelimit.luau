--!optimize 2
--!native

-- ratelimit
-- based on redbloxs Ratelimit util but made into a class
-- as i despise creating new closures (it makes me feel bad inside)
-- @kalrnlo
-- 17/06/2024

local delay = task.delay

type KeylessRatelimit = typeof(setmetatable({} :: {
	interval: number,
	limit: number,
	count: number,
}, {} :: {
	__call: (self: KeylessRatelimit) -> boolean
}))

export type Ratelimit<T> = typeof(setmetatable({} :: {
	count_map: { [T]: number },
	interval: number,
	limit: number,
}, {} :: {
	__call: (self: Ratelimit<T>, value: T) -> boolean
}))

local function delayed_remove<T>(count_map: { [T]: number }, key: T)
	count_map[key] = nil
end

local function keyed_ratelimit<T>(self: Ratelimit<T>, key: T): boolean
	local count_map = self.count_map
	local count = count_map[key]

	if not count then
		count = 0
		delay(self.interval, delayed_remove, count_map, key)
	end

	if count == self.limit then
		return false
	else
		count_map[key] = count + 1
		return true
	end
end

local function reset_count(ratelimit: KeylessRatelimit)
	ratelimit.count = 0
end

local function keyless_ratelimit(self: KeylessRatelimit): boolean
	local count = self.count

	if count == 0 then
		delay(self.interval, reset_count, self)
	end

	if count == self.limit then
		return false
	else
		self.count = count + 1
		return true
	end
end

local keyed_ratelimit_mt = {
	__call = keyed_ratelimit
}
keyed_ratelimit_mt.__index = keyed_ratelimit_mt
table.freeze(keyed_ratelimit_mt)

local unkeyed_ratelimit_mt = {
	__call = keyless_ratelimit
}
unkeyed_ratelimit_mt.__index = unkeyed_ratelimit_mt
table.freeze(unkeyed_ratelimit_mt)

local function create_keyless(limit: number, interval: number): KeylessRatelimit
	return setmetatable({
		interval = interval,
		limit = limit,
		count = 0,
	}, unkeyed_ratelimit_mt)
end

local function create_keyed<T>(self: unknown, limit: number, interval: number): Ratelimit<T>
	return setmetatable(table.freeze({
		interval = interval,
		count_map = {},
		limit = limit,
	}), keyed_ratelimit_mt)
end

local tbl = {
	keyless = create_keyless
}
local mt = {
	__call = create_keyed
}
mt.__index = mt

local export = table.freeze(setmetatable(tbl, table.freeze(mt)))

return export