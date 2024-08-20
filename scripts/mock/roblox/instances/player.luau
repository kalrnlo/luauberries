
-- player
-- implements a mock player instance for lune

local impl = require("../impl")

return impl("Player")
	:rprop("UserId", 0)