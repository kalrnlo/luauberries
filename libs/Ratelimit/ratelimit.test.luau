local ratelimit = require("ratelimit")
local testkit = require("../../testkit")

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("ratelimit", function()
	do CASE "create ratelimit"
		local check_limit = ratelimit(10, 60)
	
		check_limit("meow")
		CHECK(testkit.deq(check_limit :: any, {
			count_map = { meow = 1 },
			interval = 60,
			limit = 10,
			count = 0,
		}))
	end
	
	do CASE "will get throttled"
		local check_limit = ratelimit(10, 60)
	
		for index = 1, 10 do
			check_limit("meow")
		end
		CHECK(check_limit("meow") == false)
	end
end)

if not FINISH() then error(nil, 0) end
