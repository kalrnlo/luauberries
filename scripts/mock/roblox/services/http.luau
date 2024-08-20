
-- httpservice
-- implements a mock http service for lune

local net = require("@lune/net")
local impl = require("../impl")

return impl("HttpService")
	:rwprop("HttpEnabled", false)
