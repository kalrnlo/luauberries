# Url

Small utility with basic functions handling url queries and encoding/decoding urls

```luau
local Players = game:GetService("Players")
local safeteleport = require("safeteleport")
local url = require("url")

Players.PlayerAdded:Connect(function(player)
	local launch_data = player:GetJoinData().LaunchData
	local data = url.decode(player)

	if launch_data and #launch_data ~= 0 then
		local decoded = url.decode(launch_data)
		local placeid = tonumber(string.match(decoded, "placeId=%d+"))
		
		if placeid then
			safeteleport(placeid, player)
		end
	end
end)

```

## Methods

### `encode`

Encodes the given string using [percent-encoding](https://en.wikipedia.org/wiki/Percent-encoding), so that reserved characters, except spaces, properly encode with `%` and two hexadecimal characters. Spaces by default are encoded as `%20`, but can be specified to be encoded as `+` with the second arg.

```luau
local content = "Je suis allé au cinéma." -- French for "I went to the movies"
local encoded = url.encode(content)

print(encoded) -- "Je+suis+all%C3%A9+au+cin%C3%A9ma."
```

### `decode`

Decodes the given string, into how it originally was before being [encoded](#encode)

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

Takes a url query string, and converts it into a table with every value [decoded](#decode)

```luau
local query = "?meow=mrrp&mrrp=meow"
local tbl = url.read_query(query)

print(tbl.meow, tbl.mrrp) -- "mrrp", "meow"
```
