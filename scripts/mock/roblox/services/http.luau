
-- httpservice
-- implements a mock http service for lune

local datetime = require("@lune/datetime")
local serde = require("@lune/serde")
local net = require("@lune/net")
local impl = require("../impl")

local RANDOM_SEED = math.randomseed
local FORMAT = string.format
local RANDOM = math.random

local uuid_format = "%x%x%x%x%x%x%x%x-%x%x%x%x-4%x%x%x-%x%x%x%x-%x%x%x%x%x%x%x%x%x%x%x%x"
local wrap_in_curly_braces_format = "{%*}"
local y_hex = 0xB
local x_hex = 0xF
local x_min = 0
local y_min = 8

return impl("HttpService")
	:rwprop("HttpEnabled", false)
	:method("GenerateGUID", function(_, wrap_in_curly_braces: boolean?)
		RANDOM_SEED(datetime.now().unixTimestampMillis)
		local uuid = (FORMAT(
			uuid_format, RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), 
			RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), 
			RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), 
			RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), 
			RANDOM(y_min, y_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex),
			RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), 
			RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), 
			RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex), RANDOM(x_min, x_hex)
		))
	
		return if wrap_in_curly_braces ~= false then FORMAT(wrap_in_curly_braces_format, uuid) else uuid
	end)
	:method("JSONEncode", function(_, input: { [any]: any })
		return serde.encode("json", input)
	end)
	:method("JSONDecode", function(_, input: string)
		return serde.decode("json", input)
	end)
