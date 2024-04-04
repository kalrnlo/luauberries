--!strict
--!native

-- hugo
-- library for u64s in luau
-- @kalrnlo
-- 03/04/2024

type u64 = {number}

local function get_lows_and_highs(a: number | u64, b: number | u64)
	local b_high
	local a_high
	local a_low
	local b_low

	if type(a) == "table" then
		a_high = a[2]
		a_low = a[1]
	else
		a_low = bit32.band(a, 0xFFFFFFFF)
		a_high = bit32.rshift(a, 32)
	end

	if type(b) == "table" then
		b_high = b[2]
		b_low = b[1]
	else
		b_low = bit32.band(b, 0xFFFFFFFF)
		b_high = bit32.rshift(b, 32)
	end
	
	return a_low, a_high, b_low, b_high
end

local function get_low_and_high(n: u64 | number)
	if type(n) == "table" then
		return n[1], n[2]
	else
		return bit32.band(n, 0xFFFFFFFF), bit32.rshift(n, 32)
	end
end

local function create(n: number)
	return { bit32.band(n, 0xFFFFFFFF), bit32.rshift(n, 32) }
end

local function vararg_op(op: (...number) -> number, ...: u64 | number)
	local low, high = get_low_and_high(select(1, ...))

	for index = 2, select("#", ...) - 1 do
		local b = select(index, ...)
		high = op(high, b[2])
		low = op(low, b[1])
	end
	return { low, high }
end

local function floatify(u64: u64)
	return (u64[1] + u64[2]) * 0x100000000
end

local function le(a: u64 | number, b: u64 | number)
	local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)

	if a_high < b_high then
		return true
	elseif a_high > b_high then
		return false
	else
		return a_low <= b_low
	end
end

local function lt(a: u64 | number, b: u64 | number)
	local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)

	if a_high < b_high then
		return true
	elseif a_high > b_high then
		return false
	else
		return a_low < b_low
	end
end

local function gt(a: u64 | number, b: u64 | number)
	return not lt(a, b)
end

local function ge(a: u64 | number, b: u64 | number)
	return not le(a, b)
end

local function eq(a: u64 | number, b: u64 | number)
	local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)
	return a_low == b_low and a_high == b_high
end

local function band(...: u64 | number)
	return vararg_op(bit32.band, ...)
end

local function bxor(...: u64 | number)
	return vararg_op(bit32.bxor, ...)
end

local function bor(...: u64 | number)
	return vararg_op(bit32.bor, ...)
end

-- n is b
local function rshift(a: u64 | number, b: u64 | number)
	local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)

	local n = n % 64
	if n == 0 then return a end
	if n < 32 then
		local high = bit32.bor(bit32.rshift(a_high, b_high), bit32.lshift(a_low, 32 - n))
		local low = bit32.rshift(a_low, b_low)
		return {low, high}
	else
		local low = bit32.rshift(a_high, n - 32)
		local high = 0
		return {low, high}
	end
end

-- Addition and subtraction
local function add(a: u64 | number, b: u64 | number)
	local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)
	local lows_added = a_low + b_low

	return {
		bit32.band(lows_added, 0xFFFFFFFF),
		bit32.band(( a_high + b_high ) + bit32.rshift(lows_added, 32), 0xFFFFFFFF)
	}
end

local function sub(a: u64 | number, b: u64 | number)
	local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)
	local lows_subtracted = a_low - b_low

	return {
		bit32.band(lows_subtracted, 0xFFFFFFFF),
		bit32.band(( a_high - b_high ) - bit32.rshift(lows_subtracted, 32), 0xFFFFFFFF)
	}
end

local one_zero_u64 = { 1, 0 }
local lshift

local function fmod(a: u64 | number, b: u64 | number)
	if (if type(b) == "table" then floatify(b) else b) == 0 then
		error("[hugo] cannot divide by zero")
	end
	local rem: u64 = if type(a) == "table" then table.clone(a) else create(a)
	local b = if type(b) == "table" then b else create(b)
	local quo = table.create(2, 0)
	local b_shift = { 64, 0 }

	for index = 64, 64, -1 do
		b_shift[1] = index
		local shifted_b = lshift(b, b_shift)

		if lt(rem, shifted_b) then
			rem = sub(rem, shifted_b)
			quo = bor(quo, lshift(one_zero_u64, b_shift))
		end
	end

	return quo :: u64, rem :: u64
end

local function div(a: u64 | number, b: u64 | number)
	return (fmod(a, b))
end

local function mod(a: u64 | number, b: u64 | number): u64
	return select(2, fmod(a, b))
end

-- n is b
lshift = function(a: u64 | number, b: u64 | number): u64
	local b_low, b_high = get_low_and_high(b)
	local a = mod(a, 64)

	if eq(a, 0) then 
		return {b_low, b_high}
	elseif lt(a, 32) then
		return {
			bit32.bor(bit32.lshift(b_low, a[1]), bit32.rshift(b_high, sub(32, a))),
			bit32.lshift(b_high, a[2])
		}
	else
		return {0, bit32.lshift(b_low, sub(a, 32))}
	end
end

-- Multiplication
local function mul(a: u64 | number, b: u64 | number)
	local a_low, a_high, b_low, b_high = get_lows_and_highs(a, b)

    local a_low_b_low = create(a_low * b_low)
    local a_low_b_high = create(a_low * b_high)
    local a_high_b_low = create(a_high * b_low)
    local a_high_b_high = create(a_high * b_high)

    local carry_bit = lshift(band(add(a_low_b_high, a_high_b_low), {0xFFFF0000, 0}), {16, 0})
    local low = bor(a_low_b_low, band(carry_bit, {0xFFFF, 0xFFFF}))
    local high = bor(a_high_b_high, lshift(carry_bit,{16, 0}))

	low[2] = high[2]
    return low
end

local function tostring(u64: u64)
	return string.format("0x%08X%08X", u64[2], u64[1])
end

--------------------------------------------------------------------------------
-- buffer
--------------------------------------------------------------------------------

local function buffer_write(b: buffer, offset: number, u64: u64)

end

local function buffer_read(b: buffer, offset: number): u64

end

--------------------------------------------------------------------------------
-- exports
--------------------------------------------------------------------------------

local exports = table.freeze {
	buffer = table.freeze {
		write = buffer_write,
		read = buffer_read,
	},
	floatify = floatify,
	tostring = tostring,
	create = create,
	lshift = lshift,
	rshift = rshift,
	bxor = bxor,
	band = band,
	fmod = fmod,
	bor = bor,
	add = add,
	mul = mul,
	div = div,
	mod = mod,
	sub = sub,
	eq = eq,
	lt = lt,
	le = le,
	ge = ge,
	gt = gt,
}

return exports 