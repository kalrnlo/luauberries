--!optimize 2
--!native

-- url
-- utility functions for encoding and decoding urls

export type SpaceEncoding = "+" | "%20"

-- these dont have fast calls
local string_format = string.format
local string_gmatch = string.gmatch
local string_gsub = string.gsub

local function char_to_code(char: string): string
    return string_format("%%%02X", string.byte(char))
end

local function code_to_char(code: string): string
    return string.char(tonumber(code, 16) :: any)
end

-- i just wanted to do this because i find it funny,
-- sure its a bit less readable but its not thaaaat bad
local function encode_url(url: string, encode_spaces_as: SpaceEncoding?): string
	return (
		string_gsub(
			string_gsub(
				string_gsub(url, "([^%w _%%%-%.~])", char_to_code),
				"\n", "\r\n"
			),
			"%s+", if encode_spaces_as == "%20" then "%%20" else "+"
		)
	)
end

local function queryify(tbl: { [string]: string }, encode_spaces_as: SpaceEncoding?): string
	local query_strings = {} :: { string }

	for key, value in tbl do
		local encoded_value = encode_url(value, encode_spaces_as)
		local encoded_key = encode_url(key, encode_spaces_as)
		table.insert(query_strings, `{encoded_key}={encoded_value}`)
	end
	return `?{table.concat(query_strings, "&")}`
end

-- modified from:
-- https://devforum.roblox.com/t/233570/2
local function decode_url(url: string): string
	return (string_gsub(
		string_gsub(url, "%%(%x%x)", code_to_char), 
		"+", " "
	))
end

-- modified from: https://stackoverflow.com/questions/28916182/parse-parameters-out-of-url-in-lua
local function read_query(url: string): { [string]: string }
	local query_tbl = {} :: { [string]: string }

	for key, value: any in string_gmatch(decode_url(url), "([^&=?]-)=([^&=?]+)") do
		query_tbl[key] = value
	end
	return query_tbl
end

return table.freeze {
	read_query = read_query,
	queryify = queryify,
    decode = decode_url,
    encode = encode_url,
}
