--!strict

-- Callbacker
-- module for easily handling callbacks
-- @kalrnlo
-- 23/04/2024

local metaize = require(script.Parent.metaize)

type ConnectionPrototype<T...> = { __call: (self: Connection<T...>) -> () }
type ConnectionData<T...> = { (T...) -> () | { Connection<T...> } }
type Connection<T...> = typeof(setmetatable(
	{} :: ConnectionData<T...>, 
	{} :: ConnectionPrototype<T...>
))

local function connection_call<T...>(self: Connection<T...>)
	local arr: { Connection<T...> } = self[2] :: any

	if #arr > 1 then
		local index: number = table.find(arr, self) :: any
		arr[index] = arr[#arr]
		arr[#arr] = nil
	else
		arr[1] = nil
	end
end

local connection_prototype = metaize {
	__call = connection_call
}

local function add_callback<T...>(arr: { Connection<T...> }, callback: (T...) -> ()): Connection<T...>
	local connection_data = table.create(2) :: { (T...) -> () | { Connection<T...> } }
	connection_data[1] = callback
	connection_data[2] = arr

	local self: Connection<T...> = setmetatable(
		table.freeze(connection_data),
		connection_prototype
	) :: any

	table.insert(arr, self)
	return self
end

local function run_callbacks<T...>(arr: { Connection<T...> }, ...: T...)
	for _, connection in arr do
		task.spawn(connection[1] :: any, ...)
	end
end

local exports = table.freeze {

return add_callback, run_callbacks
