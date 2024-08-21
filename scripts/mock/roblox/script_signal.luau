

local task = require("@lune/task")

type SignalPrototype<V...> = {
	Connect: (self: Signal<V...>, f: (V...) -> ()) -> Connection<V...>,
	Once: (self: Signal<V...>, f: (V...) -> ()) -> Connection<V...>,
	Wait: (self: Signal<V...>) -> V...,
	__index: SignalPrototype<V...>,
}

type ConnectionPrototype<V...> = {
	Disconnect: (self: Connection<V...>) -> (),
	__index: ConnectionPrototype<V...>,
}

export type Connection<V...> = typeof(setmetatable({} :: {
	Connections: { (V...) -> () },
	Callback: (V...) -> (),
	Connected: boolean,
}, {} :: ConnectionPrototype<V...>))

export type Signal<V...> = typeof(setmetatable({} :: {
	Connections: { (V...) -> () },
}, {} :: SignalPrototype<V...>))

local connection = {} :: ConnectionPrototype<...any>
connection.__index = connection

function connection.Disconnect(connection)
	local connections = connection.Connections
	local index = table.find(connections, connection.Callback)

	if index then
		table.remove(connections, index)
		connection.Connected = false
	end
end

local script_signal = {} :: SignalPrototype<...any>
script_signal.__index = script_signal

function script_signal.Connect(signal, f)
	local connections = signal.Connections

	table.insert(connections, f)
	return setmetatable({
		Connections = connections,
		Connected = true,
		Callback = f,
	}, connection)
end

function script_signal.Once(signal, f)
	local connections = signal.Connections
	local callback

	callback = function(...)
		f(...)
		local index = table.find(connections, callback)

		if index then
			table.remove(connections, index)
		end
	end

	table.insert(connections, callback)

	return setmetatable({
		Connections = connections,
		Callback = callback,
		Connected = true,
	}, connection)
end

function script_signal.Wait(signal)
	local thread = coroutine.running()

	table.insert(signal.Connections, function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

local function fire<V...>(signal: Signal<V...>, ...: V...)
	for _, connection in signal.Connections do
		task.defer(connection, ...)
	end
end

local function create<S, V...>(self: S): Signal<V...>
	return table.freeze(setmetatable({
		Connections = {},
	}, script_signal))
end

table.freeze(script_signal)
table.freeze(connection)
return table.freeze(
	setmetatable({ fire = fire }, table.freeze({ __call = create }))
)
