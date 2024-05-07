--!native
--!strict

-- levintine
-- a port of fastest-levinstein to luau, with added functions for convenience
-- https://github.com/ka-weihe/fastest-levenshtein
-- @kalrnlo
-- 07/05/2024

local unclaimed_peqs = {} :: {{number}}
local size_hex = 0x10000

local function myers_32(a: string, b: string): number
	local peq_index = #unclaimed_peqs
	local peq = unclaimed_peqs[peq_index]

	if peq then
		unclaimed_peqs[peq_index] = nil
	else
		peq = table.create(size_hex, 0)
	end

	local a_bytes = { string.byte(a, 1, #a) }
    local n, m = #a, #b
    local lst = bit32.lshift(1, n - 1)
    local pv, mv, sc = -1, 0, n

    -- Set the bits for characters in string a
	for j, a_byte in a_bytes do
		peq[a_byte] = bit32.bor(peq[a_byte], bit32.lshift(1, j))
	end
	
	for i, byte in utf8.codes(b) do
		local eq = peq[byte]
		local xv = bit32.bor(eq, mv)
        eq = bit32.bor(eq, bit32.bxor(bit32.band(eq, pv) + pv, pv))
        mv = bit32.bor(mv, bit32.bnot(bit32.bor(eq, pv)))
        pv = bit32.band(pv, eq)
        if bit32.band(mv, lst) ~= 0 then
            sc += 1
        end
        if bit32.band(pv, lst) ~= 0 then
            sc -= 1
        end
        mv = bit32.bor(bit32.lshift(mv, 1), 1)
        pv = bit32.bor(bit32.lshift(pv, 1), bit32.bnot(bit32.bor(xv, mv)))
        mv = bit32.band(mv, xv)
	end

    -- Reset the peq array
	for j, a_byte in a_bytes do
		peq[a_byte] = 0
	end
	unclaimed_peqs[#unclaimed_peqs + 1] = peq

    return sc
end

local function myers_x(b: string, a: string): number
	local peq_index = #unclaimed_peqs
	local peq = unclaimed_peqs[peq_index]

	if peq then
		unclaimed_peqs[peq_index] = nil
	else
		peq = table.create(size_hex, 0)
	end

	local a_bytes = {string.byte(a, 1, #a)}
	local b_bytes = {string.byte(b, 1, #b)}
    local n, m = #a, #b
    local mhc, phc = {}, {}
    local hsize, vsize = math.ceil(n / 32), math.ceil(m / 32)
	local vmin = math.min(32, m)

    -- Initialize mhc and phc
    for i = 1, hsize do
        phc[i] = -1
        mhc[i] = 0
    end

    local j_outside = 1
    for j = 1, vsize - 1 do
        local mv, pv = 0, -1
        local start, vlen = (j - 1) * 32, (vmin + (j - 1)) * 32
		j_outside += 1

        -- Set the bits for characters in string b
        for k = start + 1, vlen, -start do
			local b_byte = b_bytes[k]
            peq[b_byte] = bit32.bor(peq[b_byte], bit32.lshift(1, k - start))
        end

        for i, byte in a_bytes do
			local index_32floor = (i // 32) + 1
			local index_32modulo = i % 32

            local eq = peq[byte]
            local pb = bit32.band(bit32.rshift(phc[index_32floor], index_32modulo), 1)
            local mb = bit32.band(bit32.rshift(mhc[index_32floor], index_32modulo), 1)
            local xv = bit32.bor(eq, mv)
            local xh = bit32.bor(bit32.bxor(bit32.band(bit32.bor(bit32.bor(eq, mb), pv), pv) + pv, pv), eq, mb)
            local ph = bit32.bor(mv, bit32.bnot(bit32.bor(xh, pv)))
            local mh = bit32.band(pv, xh)
            if bit32.bxor(bit32.rshift(ph, 31), pb) == 1 then
                phc[index_32floor] = bit32.bxor(phc[index_32floor], bit32.lshift(1, index_32modulo))
            end
            if bit32.bxor(bit32.rshift(mh, 31), mb) == 1 then
                mhc[index_32floor] = bit32.bxor(mhc[index_32floor], bit32.lshift(1, index_32modulo))
            end
            ph = bit32.bor(bit32.lshift(ph, 1), pb)
            mh = bit32.bor(bit32.lshift(mh, 1), mb)
            pv = bit32.bor(mh, bit32.bnot(bit32.bor(xv, ph)))
            mv = bit32.band(ph, xv)
        end

        -- Reset the peq array for the current block
        for k = start + 1, vlen do
            peq[b_bytes[k]] = 0
        end
    end

    local mv, pv = 0, -1
	local start = (j_outside - 1) * 32
    local vlen = math.min(32, m - start) + start

    -- Set the bits for characters in string b
    for k = start + 1, vlen, -start do
		local byte = b_bytes[k]
        peq[byte] = bit32.bor(peq[byte], bit32.lshift(1, k))
    end

    local score = m
	for i, byte in a_bytes do
		local index_32floor = (i // 32) + 1
		local index_32modulo = i % 32

        local eq = peq[byte]
        local pb = bit32.band(bit32.rshift(phc[index_32floor], index_32modulo), 1)
        local mb = bit32.band(bit32.rshift(mhc[index_32floor], index_32modulo), 1)
        local xv = bit32.bor(eq, mv)
        local xh = bit32.bor(bit32.bxor(bit32.band(bit32.bor(bit32.bor(eq, mb), pv), pv) + pv, pv), eq, mb)
        local ph = bit32.bor(mv, bit32.bnot(bit32.bor(xh, pv)))
        local mh = bit32.band(pv, xh)
        score += bit32.band(bit32.rshift(ph, m - 1), 1) - bit32.band(bit32.rshift(mh, m - 1), 1)
        if bit32.bxor(bit32.rshift(ph, 31), pb) == 1 then
            phc[index_32floor] = bit32.bxor(phc[index_32floor], bit32.lshift(1, index_32modulo))
        end
        if bit32.bxor(bit32.rshift(mh, 31), mb) == 1 then
            mhc[index_32floor] = bit32.bxor(mhc[index_32floor], bit32.lshift(1, index_32modulo))
        end
        ph = bit32.bor(bit32.lshift(ph, 1), pb)
        mh = bit32.bor(bit32.lshift(mh, 1), mb)
        pv = bit32.bor(mh, bit32.bnot(bit32.bor(xv, ph)))
        mv = bit32.band(ph, xv)
    end

    -- Reset the peq array for the last block
    for k = start + 1, vlen do
        peq[b_bytes[k]] = 0
    end

	unclaimed_peqs[#unclaimed_peqs + 1] = peq
    return score
end

local function score(str1: string, str2: string): number
	if #str1 < #str2 then
		local temp = str2
		str2 = str1
		str1 = temp
	end

	if #str2 == 0 then
		return #str1
	elseif #str1 <= 32 then
		return myers_32(str1, str2)
	else
		return myers_x(str1, str2)
	end
end

local function map(str: string, array: {string}, min_score: number?): { string }
	local min_score = min_score or 0
	local new_array = {}

	for _, array_string in array do
		local score = score(str, array_string)

		if score > min_score then
			table.insert(new_array, {
				[1] = score :: any,
				[2] = array_string,
			})
		end
	end

	table.sort(new_array, function(data1, data2)
		return data1[1] < data2[1]
	end)

	for index, data in new_array do
		new_array[index] = data[2] :: any
	end
	return (new_array :: any) :: {string}
end

-- equilvelent to fzy.hasMatch
local function has_match(match_aginst: string, str: string): boolean
	local match_aginst = string.lower(match_aginst)
	local str = string.lower(str)
	local char_index: number? = 1

	for _, character in string.split(str) do 
		char_index = (string.find(match_aginst, character, char_index))
		if not char_index then return false end
	end
	return true
end

-- gets the closest string to the provided string in an array
local function closest(str: string, array: {string}): (string, number)
	local closest_score = math.huge
	local closest_string: string

	for _, array_string in array do
		local score = score(str, array_string)

		if score < closest_score then
			closest_string = array_string
			closest_score = score
		end
	end
	return closest_string, closest_score
end

local function sort(str: string, array: {string})
	table.sort(array, function(str1, str2)
		return score(str, str1) < score(str, str2)
	end)
end

local exports = table.freeze {
	has_match = has_match,
	closest = closest,
	score = score,
	sort = sort,
	map = map,
}

return exports