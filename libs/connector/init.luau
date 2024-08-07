--!native

-- connector
-- utility for handling event callbacks

local cross = require("../cross")

type ConnectionPrototype<A...> = {
	__call: (self: Connection<A...>) -> ()
}

export type Connection<A...> = typeof(setmetatable({} :: {
	connections: Connections<A...>,
	f: (A...) -> (),
}, {} :: ConnectionPrototype<A...>))

export type Connections<A...> = { Connection<A...> }

local function disconnect<A...>(connection: Connection<A...>)
	local connections = connection.connections
	local index = table.find(connections, connection)

	if index then
		if index ~= 1 then
			local len = #connections
			connections[index] = connections[len]
			connections[len] = nil
		else
			connections[1] = nil
		end
	end	
end

local connection_mt = table.freeze({
	__call = disconnect
})
local connector = {}

function connector.spawn<A...>(connections: Connections<A...>, ...: A...)
	for _, connection in connections do
		cross.spawn(connection.f, ...)
	end
end

function connector.defer<A...>(connections: Connections<A...>, ...: A...)
	for _, connection in connections do
		cross.defer(connection.f, ...)
	end
end

function connector.connection<A...>(
	connections: Connections<A...>,
	f: (A...) -> ()
): Connection<A...>
	local connection = setmetatable({
		connections = connections,
		f = f,
	}, connection_mt)

	table.insert(connections, connection)
	return table.freeze(connection)
end

return table.freeze(connector)