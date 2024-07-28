local testkit = require("../testkit")
local task = require("@lune/task")
local race = require("race")

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("RACE", function()
	CASE("MAIN")

	local result = race({
		function(str: string) 
			task.wait(5)
			return `{str}! i never return ;c`
		end,
		function(str: string)
			task.wait(3)
			return `{str}! i return!`
		end
	}, "yay")
		
	CHECK(result == "yay! i return!")
end)

return FINISH