local testkit = require("../../testkit")
local rbxthumb = require("rbxthumb")

local TEST, CASE, CHECK, FINISH = testkit.test()

-- making an enum global rq so no errors occur in lune
Enum = table.freeze({
	AvatarItemType = table.freeze({
		Asset = 1,
	})
})

TEST("rbx thumb", function()

end)