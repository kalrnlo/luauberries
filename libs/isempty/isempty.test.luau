local testkit = require("../testkit")
local isempty = require("isempty")

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("isempty", function()
	do CASE("empty table")
		CHECK(isempty({}))
	end

	do CASE("filled table")
		CHECK(isempty({ meow = "mrrp" }) == false)
	end
end)

if not FINISH() then error(nil, 0) end