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
local function merge_arrays_unique_only<V>(a: { V }, b: { V }): { V }
	local result_tbl = table.clone(a)

	for _, value in b do
		if not table.find(result_tbl, value) then
			table.insert(result_tbl, value)
		end
	end
	return result_tbl
end

local function deepfreeze<T>(tbl: T & {}): T
	local tbl = tbl :: any

	for index, value in tbl do
		if type(value) == "table" then
			tbl[index] = deepfreeze(value :: any)
		end
	end
	return table.freeze(tbl) :: any
end

local function frozen_deepclone<T>(tbl: T & {}): T
    local clone = table.clone(tbl)
    
	for index, value in clone do
		if type(value) == "table" then
			clone[index] = frozen_deepclone(value :: any)
		elseif type(value) == "buffer" then
			clone[index] = CLONE_BUFFER(value)
		end
	end
	return table.freeze(clone) :: any
end

local function deepclone<T>(tbl: T & {}): T
    local clone = table.clone(tbl)
    
	for index, value in clone do
		if type(value) == "table" then
			clone[index] = deepclone(value :: any)
		elseif type(value) == "buffer" then
			clone[index] = CLONE_BUFFER(value)
		end
	end
	return clone :: any
end

local function clone_val<Value>(value: Value): Value
	return if type(value) == "table" then 
			deepclone(value) 
		elseif type(value) == "buffer" then 
			CLONE_BUFFER(value) :: any 
		else 
			value
end

local function clone_default_val<Value, Metadata>(
	chest: t.Chest<Value, Metadata>, 
	key: string
): Value
	local getter = chest.default_value_getter
	return if getter then getter(key) else clone_val(chest.default_value :: any)
end

local function reconcile<T>(original: { [any]: any }, template: T & {}): T
	local tbl = table.clone(original)
	local template = template :: any

	for key, value: any in template :: {} do
		local tbl_key = tbl[key]

		if not tbl_key then
			tbl[key] = clone_val(value)
		elseif type(tbl_key) == "table" and type(value) == "table" then
			tbl[key] = reconcile(tbl_key, value)
		end
	end

	return tbl :: any
end

local function clone_default_val<Value, Metadata>(
	chest: t.Chest<Value, Metadata>, 
	key: string
): Value
	local getter = chest.default_value_getter
	return if getter then getter(key) else clone_val(chest.default_value :: any)
end

return table.freeze({
	merge_arrays_unique_only = merge_arrays_unique_only,
	clone_default_val = clone_default_val,
	frozen_deepclone = frozen_deepclone,
	clone_buf = CLONE_BUFFER,
	deepfreeze = deepfreeze,
	deepclone = deepclone,
	clone_val = clone_val,
	reconcile = reconcile,
})