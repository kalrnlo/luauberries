--!strict
--!native

-- hugo
-- library for u64s in luau
-- @kalrnlo
-- 03/04/2024

local function get_lows_and_highs(a: number | u64, b: number | u64)
    return (
        if type(a) == "table" then
           (a[1], a[2])
        else
            (bit32.band(a, 0xFFFFFFFF), bit32.rshift(a, 32))
    ), (
        if type(b) == "table" then
           (b[1], b[2])
        else
            (bit32.band(b, 0xFFFFFFFF), bit32.rshift(b, 32))
    )
end

local function create(n: number)
    return { bit32.band(n, 0xFFFFFFFF), bit32.rshift(b, 32) }
end

local function vararg_op(op: (...number) -> number, ...: u64 | number)
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

local function lshift(a: u64 | number, b: u64 | number) 
    local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)

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

local function floatify(u64: u64)
    return (u64[1] + u64[2]) * 0x100000000
end

local function le(a: u64 | number, b: u64 | number)
    if a[2] < b[2] then
        return true
    elseif a[2] > b[2] then
        return false
    else
        return a[1] <= b[1]
    end
end

local function lt(a: u64 | number, b: u64 | number)
    if a[2] < b[2] then
        return true
    elseif a[2] > b[2] then
        return false
    else
        return a[1] < b[1]
    end
end

local function ge(a: u64 | number, b: u64 | number)
    return not le(a, b)
end

local function q(a: u64 | number, b: u64 | number)
	return a[1] == b[1] and a[2] == b[2]
end

local function band(...: u64 | number)
	return bitwise_vararg_op(bit32.band, ...)
end

local function bxor(...: u64 | number)
	return bitwise_vararg_op(bit32.bxor, ...)
end

local function bor(...: u64 | number)
	return bitwise_vararg_op(bit32.bor, ...)
end

-- n is b
local function lshift(a: u64 | number, b: u64 | number)
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
local function rshift(a: u64 | number, b: u64 | number)
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
local function add(a: u64 | number, b: u64 | number)
	local lows_added = a[1] + b[1]

	return setmetatable(
		{
			bit32.band(lows_added, 0xFFFFFFFF),
			bit32.band(( a[2] + b[2] ) + bit32.rshift(lows_added, 32), 0xFFFFFFFF)
		},
		u64
	)
end

local function sub(a: u64 | number, b: u64 | number)
	local lows_subtracted = a[1] - b[1]

	return setmetatable(
		{
			bit32.band(lows_subtracted, 0xFFFFFFFF),
			bit32.band(( a[2] - b[2] ) - bit32.rshift(lows_subtracted, 32), 0xFFFFFFFF)
		},
		u64
	)
end

local function mul(a: u64 | number, b: u64 | number)
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

local one_zero_u64 = setmetatable({ 1, 0 }, u64)

local function fmod(a: u64 | number, b: u64 | number)
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

local function div(a: u64 | number, b: u64 | number)
    return (u64_fmod(a, b))
end

local function mod(a: u64 | number, b: u64 | number)
    return select(2, u64_fmod(a, b))
end

local function tostring(u64: u64)
	return string.format("0x%08X%08X", u64[2], u64[1])
end

--------------------------------------------------------------------------------
-- i64
--------------------------------------------------------------------------------

local function i64_mul(a: i64, b: i64)
    local a_low = a[1]
    local a_high = a[2]
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

--------------------------------------------------------------------------------
-- buffer
--------------------------------------------------------------------------------

local function buffer_writeu64(b: buffer, offset: number, u64: u64)

end

local function buffer_readu64(b: buffer, offset: number): u64

end

local function buffer_writei64(b: buffer, offset: number, i64: i64)

end

local function buffer_readi64(b: buffer, offset: number): i64

end

--------------------------------------------------------------------------------
-- exports
--------------------------------------------------------------------------------

local exports = table.freeze {
    buffer = table.freeze {
        write = buffer_write,
        read = buffer_read,
    }
    floatify = floatify,
    tostring = tostring,
    create = create,
    lshift = lshift,
    rshift = rshift,
    bxor = bxor,
    band = band,
    fmod = fmod,
    idiv = idiv,
    bor = bor,
    add = add,
    mul = mul,
    div = div,
    mod = mod,
    eq = eq,
    lt = lt,
    le = le,
    ge = ge,
    gt = gt,
}

return exports 