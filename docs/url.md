# Url

Small utility with basic functions handling url querys and encoding/decoding urls

```luau
local Players = game:GetService("Players")
local safeteleport = require("safeteleport")
local url = require("url")

Players.PlayerAdded:Connect(function(player)
	local data = url.launchdata(player)

	if data then
		local placeid = tonumber(string.match(data, "placeid=%d+"))
		
		if placeid then
			safeteleport(placeid, player)
		end
	end
end)

```

## Methods

### `encode`

Encodes the given string using [percent-encoding](https://en.wikipedia.org/wiki/Percent-encoding), so that reserved characters except for spaces properly encode with `%` and two hexadecimal characters. Spaces by defualt are encoded as `%20`, but can be specified to be encoded as `+` with the second arg.

```luau
local content = "Je suis allé au cinéma." -- French for "I went to the movies"
local encoded = url.encode(content)

print(encoded) -- "Je+suis+all%C3%A9+au+cin%C3%A9ma."
```

### `decode`

Decodes the given string, into how it originally was before it was [encoded](#encode)

> [!NOTE]
> If the spaces in the url are encoded as `+`, you need to specifiy this using the second arg for it to be properly decoded

```luau
local encoded = "Je%20suis%20all%C3%A9%20au%20cinema%2E"
local decoded = url.decode(input)

print(decoded) -- "Je suis allé au cinéma."
```

### `queryify`

Takes a dictionary, and converts it into a url query string, and [encodes](#encode) every key and value

```luau
local query = url.queryify({
	meow = "mrrp",
	mrrp = "meow"
})

print(query) -- "?meow=mrrp&mrrp=meow"
```

### `read_query`

Takes in a url query string, and converts it into a table with every value [decoded](#decode)

```luau
local query = "?meow=mrrp&mrrp=meow"
local tbl = url.read_query(query)

print(tbl.meow, tbl.mrrp) -- "mrrp", "meow"
```

### `get_launchdata`

Gets the launchdata for the given player (the actual launchdata not the full join url that [`Player:GetJoinData().LaunchData`](https://create.roblox.com/docs/reference/engine/classes/Player#GetJoinData) gives), and decodes it

```luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local launchdata = url.get_launchdata(player)

	if launchdata then
		print(`{player.Name}'s launchdata: {launchdata}`)
	end
end)
```