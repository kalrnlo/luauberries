--!optimize 2
--!native

-- url
-- utility functions for encoding and decoding urls

export type SpaceEncoding = "+" | "%20"

local LAUNCH_DATA_START = "&launchdata="
local START_LEN = #LAUNCH_DATA_START
local FORMAT = string.format
local GMATCH = string.gmatch
local MATCH = string.match
local GSUB = string.gsub

local function CHAR_TO_CODE(char: string): string
    return FORMAT("%%%02X", string.byte(char))
end

local function CODE_TO_CHAR(code: string): string
    return string.char(tonumber(code, 16) :: any)
end

-- modified from:
-- https://devforum.roblox.com/t/233570/2
local function DECODE(url: string, spaces_encoded_as: SpaceEncoding?): string
	local chars_decoded = GSUB(url, "%%(%x%x)", CODE_TO_CHAR)

	if spaces_encoded_as == "+" then
		return (GSUB(chars_decoded, "+", " "))
	else
		return chars_decoded
	end
end

local function ENCODE(url: string, encode_spaces_as: SpaceEncoding?): string
	local space_encode_char = if encode_spaces_as == "+" then "+" else "%%20"
	local chars_encoded = (GSUB(url, "([^%w _%%%-%.~])", CHAR_TO_CODE))
	local new_line_encoded = (GSUB(chars_encoded, "\n", "\r\n"))

	return (GSUB(new_line_encoded, "%s+", space_encode_char))
end

local url = {}

function url.get_launchdata(player: Player, launchdata_spaces_encoded_as: SpaceEncoding?): string?
	local launch_data = player:GetJoinData().LaunchData

	if launch_data and #launch_data ~= 0 then
		local decoded = DECODE(launch_data, launchdata_spaces_encoded_as)
		-- pattern for getting a string with a non zero length
		-- right after "&launchdata=" that doesn't include the & character
		return MATCH(decoded, "&launchdata=([^&]+)")
	else
		return nil
	end
end

-- modified from: https://stackoverflow.com/questions/28916182/parse-parameters-out-of-url-in-lua
function url.read_query(url: string, spaces_encoded_as: SpaceEncoding?): { [string]: string }
	local query_tbl = {}

	for key, value: any in GMATCH(DECODE(url, spaces_encoded_as), "([^&=?]-)=([^&=?]+)") do
		query_tbl[key] = value
	end
	return query_tbl
end

function url.queryify(t: { [string]: string }, encode_spaces_as: SpaceEncoding?): string
	local query_strings = {} :: { string }

	for key, value in t do
		local encoded_value = ENCODE(value, encode_spaces_as)
		local encoded_key = ENCODE(key, encode_spaces_as)
		table.insert(query_strings, `{encoded_key}={encoded_value}`)
	end
	return `?{table.concat(query_strings, "&")}`
end

url.encode = ENCODE
url.decode = DECODE

return table.freeze(url)
