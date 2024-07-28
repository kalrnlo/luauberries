--!optimize 2
--!native

-- ratelimit
-- based on redbloxs Ratelimit util but made into a class
-- as i despise creating new closures (it makes me feel bad inside)

type RatelimitPrototype<K> = {
	__call: (ratelimit: Ratelimit<K>, key: K?) -> boolean
}

export type Ratelimit<K> = typeof(setmetatable({} :: {
	count_map: { [K]: number },
	interval: number,
	limit: number,
}, {} :: RatelimitPrototype<K>))

local COUNT = newproxy()
local DELAY = (function()
	if task then
		return task.delay
	elseif string.find(_VERSION, "lune") then
		return (require)("@lune/task").delay
	else
		return function()
			
		end :: any
	end
end)()

local ratelimit_mt = ({} :: any) :: RatelimitPrototype<any>

function ratelimit_mt.__call(ratelimit, key)
        local key = key or COUNT
        local count_map = ratelimit.count_map
	local count = count_map[key]

	if not count then
		count = 0
		DELAY(ratelimit.interval, function(count_map: { [any]: number }, key: any)
		        count_map[key] = nil
		end, count_map, key)
	end

	if count == ratelimit.limit then
		return false
	else
		count_map[key] = count + 1
		return true
	end
end

local function create<K>(limit: number, interval: number): Ratelimit<K>
	return setmetatable({
		interval = interval,
		count_map = {},
		limit = limit,
	}, ratelimit_mt)
end

return create
