
-- httpservice
-- implements a mock http service for lune

local serde = require("@lune/serde")
local net = require("@lune/net")
local impl = require("../impl")

return impl("HttpService")
	:rwprop("HttpEnabled", false)
	:method("RequestAsync", function(_)

	end)
	:method("PostAsync", function(_)

	end)
	:method("GetAsync", function(_)

	end)
	:method("PatchAsync", function(_)

	end)
	:method("PatchAsync", function(_)

	end)
	:method("GenerateGUID", function(_)

	end)
	:method("GetSecret", function()

	end)
	:method("JSONEncode", function(_, input: { [any]: any })
		return serde.encode("json", input)
	end)
	:method("JSONDecode", function(_, input: string)
		return serde.decode("json", input)
	end)
