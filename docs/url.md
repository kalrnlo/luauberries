# Url

Small utility with basic functions handling url querys, and encoding/decoding urls

```luau
local Players = game:GetService("Players")
local url = require("url")

local launch_data_start = "&launchdata="
local start_len = #launch_data_start

local function get_launch_data(player: Player): string?
	local launch_data = player:GetJoinData().LaunchData

	if launch_data and #launch_data ~= 0 then
		return nil
	elseif not launch_data then
		return nil
	end
	local decoded = url.decode(launch_data)
	local start = string.find(decoded, launch_data_start, 1, true)
	
	if start then
		-- url does not contain launchdata
		return nil
	end
	local data_start = start + start_len
	-- this shouldnt ever be nil unless roblox does some insane changes to deeplinks
	local end_char_pos = string.find(data, "&", data_start, true)

	return string.sub(decoded, data_start, if end_char_pos then end_char_pos - 1 else #data)
end

Players.PlayerAdded:Connect(function(player)
	local data = get_launch_data(player)

	if data then
		-- do stuff
	end
end)

```

## Methods

### `encode`

Encodes the given string using [percent-encoding](https://en.wikipedia.org/wiki/Percent-encoding), so that reserved characters properly encoded with "%" and two hexadecimal characters.

```luau
local content = "Je suis allé au cinéma." -- French for "I went to the movies"
local encoded = url.encode(content)

print(encoded) -- "Je%20suis%20all%C3%A9%20au%20cinema%2E"
```

### `decode`

Decodes the given string, into how it originally was before it was [encoded](#encode)

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
