--!optimize 2
--!native
--!strict

-- random
-- functional version of the roblox random class, thats 80% in luau
-- @kalrnlo
-- 23/05/2024

local math_randomseed = math.randomseed
local math_random = math.random
local ZERO_VEC = Vector3.zero
local NEG_PI = -math.pi
local SEED: number

@checked
local function SET_SEED(seed: number?)
	SEED = seed or os.clock()
	math_randomseed(SEED)
end

@checked
local function int(min: number?, max: number?, seed: number?): number
	SET_SEED(seed)
	return math_random(min or NEG_PI, max or math.pi)
end

@checked
local function float(min: number?, max: number?, seed: number?): number
	SET_SEED(seed)
	local real_min = min or math_random()
	SET_SEED(seed)
	local real_max = max or math_random(real_min)
	
	SET_SEED(seed)
	return real_min + (math_random() * (real_max - real_min))
end

@checked
local function vector(min: Vector3?, max: Vector3?, seed: number?): Vector3
	local max = max or Vector3.new(
		float(0, nil, seed),
		float(0, nil, seed),
		float(0, nil, seed)
	).Unit
	local min = min or ZERO_VEC

	return Vector3.new(
		float(min.X, max.X, seed),
		float(min.Y, max.Y, seed),
		float(min.Z, max.Z, seed)
	).Unit
end

@checked
local function shuffle<V>(arr: { V }, seed: number?): { V }
	local new_arr = table.clone(arr)
	local len = #new_arr

	for index, value in new_arr do
		local random_index = int(index, len, seed)
		new_arr[index] = new_arr[random_index]
		new_arr[random_index] = value
	end
	return new_arr
end

@checked
local function index<V>(arr: { V }, seed: number?): V
	return arr[int(1, #arr, seed)]
end

@checked
local function get_seed(): number
	return SEED
end

local tbl = {
	shuffle = shuffle,
	seed = get_seed,
	vector = vector,
	float = float,
	index = index,
	int = int,
}

local mt = {
	__call = @checked function(self: unknown, min: number?, max: number?, seed: number?): number
		return int(min, max, seed)
	end
}
mt.__index = mt

-- calling this here so that if somebody calls seed() before the variable is set it doesnt come up nil
SET_SEED()

return table.freeze(setmetatable(tbl :: any, table.freeze(mt))) :: typeof(setmetatable(tbl, {} :: {
	__call: (self: unknown, min: number?, max: number?, seed: number?) -> number
}))


