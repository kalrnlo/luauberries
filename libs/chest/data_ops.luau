--!optimize 2
--!native

-- data ops
-- util for dealing with datastore values

local t = require("types")

local function CLONE_BUFFER(buf: buffer): buffer
	local new_buffer = buffer.create(buffer.len(buf))
	buffer.copy(new_buffer, 0, buf)
	return new_buffer
end

-- merges a & b into one array, eliminating duplicate values
local function MERGE_ARRAYS_UNIQUE_ONLY<V>(a: { V }, b: { V }): { V }
	local result_tbl = table.clone(a)

	for _, value in b do
		if not table.find(result_tbl, value) then
			table.insert(result_tbl, value)
		end
	end
	return result_tbl
end

local function DEEP_FREEZE<T>(tbl: T & {}): T
	local tbl = tbl :: any

	for index, value in tbl do
		if type(value) == "table" then
			tbl[index] = DEEP_FREEZE(value :: any)
		end
	end
	return table.freeze(tbl) :: any
end

local function FROZEN_DEEPCLONE<T>(tbl: T & {}): T
    local clone = table.clone(tbl)
    
	for index, value in clone do
		if type(value) == "table" then
			clone[index] = FROZEN_DEEPCLONE(value :: any)
		elseif type(value) == "buffer" then
			clone[index] = CLONE_BUFFER(value)
		end
	end
	return table.freeze(clone) :: any
end

local function DEEPCLONE<T>(tbl: T & {}): T
    local clone = table.clone(tbl)
    
	for index, value in clone do
		if type(value) == "table" then
			clone[index] = DEEPCLONE(value :: any)
		elseif type(value) == "buffer" then
			clone[index] = CLONE_BUFFER(value)
		end
	end
	return clone :: any
end

local function CLONE_VAL<Value>(value: Value): Value
	return if type(value) == "table" then 
			DEEPCLONE(value) 
		elseif type(value) == "buffer" then 
			CLONE_BUFFER(value) :: any 
		else 
			value
end

local function RECONCILE<T>(original: { [any]: any }, template: T & {}): T
	local tbl = table.clone(original)
	local template = template :: any

	for key, value: any in template :: {} do
		local tbl_key = tbl[key]

		if not tbl_key then
			tbl[key] = CLONE_VAL(value)
		elseif type(tbl_key) == "table" and type(value) == "table" then
			tbl[key] = RECONCILE(tbl_key, value)
		end
	end

	return tbl :: any
end

local function CLONE_DEFAULT_VAL<Value, Metadata>(
	chest: t.Chest<Value, Metadata>, 
	key: string
): Value
	local getter = chest.default_value_getter
	return if getter then getter(key) else CLONE_VAL(chest.default_value :: any)
end

return table.freeze({
	MERGE_ARRAYS_UNIQUE_ONLY = MERGE_ARRAYS_UNIQUE_ONLY,
	CLONE_DEFAULT_VAL = CLONE_DEFAULT_VAL,
	FROZEN_DEEPCLONE = FROZEN_DEEPCLONE,
	CLONE_BUF = CLONE_BUFFER,
	DEEP_FREEZE = DEEP_FREEZE,
	DEEPCLONE = DEEPCLONE,
	CLONE_VAL = CLONE_VAL,
	RECONCILE = RECONCILE,
})