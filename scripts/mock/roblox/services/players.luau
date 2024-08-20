
-- players
-- implements a mock players service for lune

local impl = require("../impl")

return impl("Players")
	:method("GetPlayers", function(players)
		return players:GetChildren()
	end)
