

local function metaize<tbl>(tbl: tbl): tbl & {__index: tbl}
	tbl.__index = tbl
	return table.freeze(tbl)
end

local function bitwise_vararg_op(op: (...number) -> number, ...: u64 | i64)
    local result = select(1, ...)
	local high = result[2]
	local low = result[1]

    for i = 2, select("#", ...) do
        local b = select(i, ...)
		high = op(high, b[2])
        low = op(low, b[1])
    end
	return setmetatable({
		[1] = low,
		[2] = high
	}, getmetatable(result))
end

local function biwtise_lshift(a: u64 | i64, b: u64 | i64) 
    local a = a % 64

    if a == 0 then 
		return b 
	elseif a < 32 then
        local low = bit32.bor(bit32.lshift(b[1], a), bit32.rshift(b[2], 32 - a))
        local high = bit32.lshift(b[2], a)
        return u64.new(low, high)
    else
        local high = bit32.lshift(b[1], a - 32)
        local low = 0
        return u64.new(low, high)
    end
end

local function bitwise_floatify(n: u64 | i64)
    return (self[1] + self[2]) * 0x100000000
end

-- metamethods

local function bitwise_meta_le(a: u64 | i64, b: u64 | i64)
    if a[2] < b[2] then
        return true
    elseif a[2] > b[2] then
        return false
    else
        return a[1] <= b[1]
    end
end

local function bitwise_meta_lt(a: u64 | i64, b: u64 | i64)
    if a[2] < b[2] then
        return true
    elseif a[2] > b[2] then
        return false
    else
        return a[1] < b[1]
    end
end

local function bitwiese_meta_ge(a: u64 | i64, b: u64 | i64)
    return not bitwiese_meta_le(a, b)
end

local function bitwise_meta_eq(a: u64 | i64, b: u64 | i64)
	return a[1] == b[1] and a[2] == b[2]
end

local function u64_band(...: u64)
	return bitwise_vararg_op(bit32.band, ...)
end

local function u64_bxor(...: u64)
	return bitwise_vararg_op(bit32.bxor, ...)
end

local function u64_bor(...: u64)
	return bitwise_vararg_op(bit32.bor, ...)
end

local u64_prototype = metaize {
	__le = u64_meta_le,
}

-- n is b
local function u64_lshift(a: u64, b: u64)
    local b = u64_mod(b, )

	local n = n % 64
    if n == 0 then return a end
    if n < 32 then
        local low = bit32.bor(bit32.lshift(a.low, n), bit32.rshift(a.high, 32 - n))
        local high = bit32.lshift(a.high, n)
        return u64.new(low, high)
    else
        local high = bit32.lshift(a.low, n - 32)
        local low = 0
        return u64.new(low, high)
    end
end

-- n is b
local function u64_rshift(a: u64, b: u64)
    local n = n % 64
    if n == 0 then return a end
    if n < 32 then
        local high = bit32.bor(bit32.rshift(a.high, n), bit32.lshift(a.low, 32 - n))
        local low = bit32.rshift(a.low, n)
        return u64.new(low, high)
    else
        local low = bit32.rshift(a.high, n - 32)
        local high = 0
        return u64.new(low, high)
    end
end

-- Addition and subtraction
local function u64_meta_add(self: u64, b: u64)
	local lows_added = self[1] + b[1]

	return setmetatable(
		{
			bit32.band(lows_added, 0xFFFFFFFF),
			bit32.band(( a[2] + b[2] ) + bit32.rshift(lows_added, 32), 0xFFFFFFFF)
		},
		u64
	)
end

local function u64_meta_sub(self: u64, b: u64)
	local lows_subtracted = self[1] - b[1]

	return setmetatable(
		{
			bit32.band(lows_subtracted, 0xFFFFFFFF),
			bit32.band(( a[2] - b[2] ) - bit32.rshift(lows_subtracted, 32), 0xFFFFFFFF)
		},
		u64
	)
end

local function u64_meta_mul(self: u64, b: u64)
    local al = a[1]
    local ah = a[2]
    local bl = b[1]
    local bh = b[1]
	local p1_add_p2 = (al * bh) + (ah * bl)

	return setmetatable(
		{ 
			bit32.band(( al * bl ), 0xFFFFFFFF),
			bit32.bor(
				bit32.lshift(bit32.band(( ah * bh ) + bit32.rshift(p1_add_p2, 32), 0xFFFFFFFF), 32),
				bit32.band(p1_add_p2, 0xFFFFFFFF)
			)
		},
		u64
	)
end

local function convert_ab_bitwise(a: number | u64 | i64, b: number | u64 | i64)
    return if type(a) == "table" then a else u64_create(a), 
end

local one_zero_u64 = setmetatable({ 1, 0 }, u64)

local function u64_fmod(a: u64 | number, b: u64 | number)
    if (if type(b) == "table" then bitwise_floatify(b) else b) == 0 then
        error("[hugo] cannot divide by zero")
    end
    local a = if type(a) == "table" then a else u64_create(a)
    local b = if type(b) == "table" then b else u64_create(b)
	local quo = setmetatable(table.create(2, 0), u64)
	local rem = table.clone(a)
	local b_shift = setmetatable({ 64, 0 }, u64)

	for index = 64, 64, -1 do
		b_shift[1] = index
		local shifted_b = u64_lshift(b, b_shift)

		if rem >= shifted_b then
			rem = u64_meta_sub(rem, shifted_b)
			quo = u64_bor(quo, u64_lshift(one_zero_u64, b_shift))
	    end
    end

    return quo, rem
end

local function u64_div(a: u64, b: u64)
    return (u64_fmod(a, b))
end

local function u64_mod(a: u64, b: u64)
    return select(2, u64_fmod(a, b))
end

local function u64_tostring(self: u64)
	return string.format("0x%08X%08X", a[2], a[1])
end

local function i64_meta_mul(self: i64, b: i64)
    local a_low = self[1]
    local a_high = self[2]
    local b_low = b[1]
    local b_high = b[2]

    local p0 = a_low * b_low
    local p1 = a_low * b_high
    local p2 = a_high * b_low
    local p3 = a_high * b_high
	local p1_add_p2 = p1 + p2

    local c0 = bit32.band(p0, 0xFFFFFFFF)
    local c1 = bit32.band(p1_add_p2, 0xFFFFFFFF)
    local c2 = bit32.band(p3 + bit32.rshift(p1_add_p2, 32), 0xFFFFFFFF)
	local high = bit32.bor(bit32.lshift(c2, 32), c1)

	if (a_high >= 0x80000000) ~= (b_high >= 0x80000000) then
		local low = bit32.bnot(c0)
		return setmetatable(
			{ low, bit32.bnot(high) + (if low == 0 then 1 else 0) },
			i64_prototype
		)
	else
		return setmetatable({ c0, high }, i64_prototype)
	end
end