# Connector

Utility for handling event callbacks

```luau
local connector = require("connector")
local connections = {} :: connector.Connections<boolean, string>

connector.connection(connections, function(success, responce)
	if success then
		print(`mrrp success!!\n\tresponce:{responce}`)
	end
end)

connector.spawn(connections, true, ":3")

```

## Types

### `Connection`

```luau
type Connection<A...> = typeof(setmetatable({} :: {
	connections: Connections<A...>,
	f: (A...) -> (),
}, {} :: {
	__call: (self: Connection<A...>) -> ()
}))

```

* `connections` - a reference back to the connections table for disconnecting
* `f` - the connections callback

### `Connections`

```luau
type Connections<A...> = { Connection<A...> }
```

## Methods

### `connection`

Creates a new connection object, and inserts it to the [`connections`](#connections) table

```luau
local connections = {} :: connector.Connections<string>

connector.connection(connections, function(name)
	print(`hi {name}!`)
end)
```

### `spawn`

Runs every connection in the connections table with the given arguments, and creates a new thread for each connection to run the given connection

```luau
local connections = {} :: connector.Connections<string, string>
connector.spawn(connections, "mrrp", "meow :3")

```

### `defer`

Same as [`spawn`](#spawn) except that it uses [`defer`](https://libs.luau.lol/cross#defer), rather than [`spawn`](https://libs.luau.lol/cross#spawn) for creating threads

```luau
local connections = {} :: connector.Connections<string>
connector.defer(connections, "meowzers")
```