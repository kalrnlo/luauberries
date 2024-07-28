local ratelimit = require("ratelimit")
local testkit = require("../../testkit")

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("ratelimit", function()
	do CASE "create ratelimit"
		local check_limit = ratelimit(10, 60)

		CHECK(testkit.deq(check_limit :: any, {
			count_map = {},
			interval = 60,
			limit = 10,
		}))
	end

	do CASE "call without key"
		local check_limit = ratelimit(10, 60)

                check_limit()
		CHECK(function()
                for key, count in check_limit.count_map do
                return type(key) == "userdata" and count == 1
                end
                end)
	end

	do CASE "call with key"
		local check_limit = ratelimit(10, 60)

                check_limit("meow")
		CHECK(testkit.deq(check_limit :: any, {
			count_map = { meow = 1 },
			interval = 60,
			limit = 10,
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
