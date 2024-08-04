local testkit = require("../../testkit")
local retryer = require("init")

local TEST, CASE, CHECK, FINISH, SKIP = testkit.test()
local ATTEMPTS = 0

local function meower(kitty: string, catter: string): (string, string)
	ATTEMPTS += 1

	if ATTEMPTS % 2 or ATTEMPTS == 1 then
		error("lmao")
	end

	return `{kitty} :3`, `{catter} 🐈`
end

TEST("retryer", function()
	if true then
		return
	end

	do CASE("__call")
		local success1, ret1_1, ret1_2 = retryer(1, meower, "meow", "mrrow")	
		local success2, ret2_1, ret2_2 = retryer(5, meower, "meow", "mrrow")

		CHECK(
			success1 == false and ret1_1 == "lmao" and ret1_2 == nil and
			success2 == true and ret2_1 == "meow :3" and ret2_2 == "mrrow 🐈"
		)
	end

	do CASE("delay")
		ATTEMPTS = 0
		local success1, ret1_1, ret1_2 = retryer.delay(2, 1, meower, "meow", "mrrow")	
		local success2, ret2_1, ret2_2 = retryer.delay(2, 5, meower, "meow", "mrrow")

		CHECK(
			success1 == false and ret1_1 == "lmao" and ret1_2 == nil and
			success2 == true and ret2_1 == "meow :3" and ret2_2 == "mrrow 🐈"
		)
	end

	do CASE("exp")
		ATTEMPTS = 0
		local success1, ret1_1, ret1_2 = retryer.exp(2, .5, 1, meower, "meow", "mrrow")	
		local success2, ret2_1, ret2_2 = retryer.exp(2, .5, 5, meower, "meow", "mrrow")

		CHECK(
			success1 == false and ret1_1 == "lmao" and ret1_2 == nil and
			success2 == true and ret2_1 == "meow :3" and ret2_2 == "mrrow 🐈"
		)
	end

	do CASE("inf")
		ATTEMPTS = 0
		local ret1_1, ret1_2 = retryer.inf(meower, "meow", "mrrow")	
		local ret2_1, ret2_2 = retryer.inf(meower, "meow", "mrrow")

		CHECK(
			ret1_1 == "meow :3" and ret1_2 == "mrrow 🐈" and
			ret2_1 == "meow :3" and ret2_2 == "mrrow 🐈"
		)
	end

	do CASE("infdelay")
		ATTEMPTS = 0
		local ret1_1, ret1_2 = retryer.infdelay(1, meower, "meow", "mrrow")	
		local ret2_1, ret2_2 = retryer.infdelay(1, meower, "meow", "mrrow")

		CHECK(
			ret1_1 == "meow :3" and ret1_2 == "mrrow 🐈" and
			ret2_1 == "meow :3" and ret2_2 == "mrrow 🐈"
		)
	end

	do CASE("infexp")
		ATTEMPTS = 0
		local ret1_1, ret1_2 = retryer.infexp(1, .5, meower, "meow", "mrrow")	
		local ret2_1, ret2_2 = retryer.infexp(1, .5, meower, "meow", "mrrow")

		CHECK(
			ret1_1 == "meow :3" and ret1_2 == "mrrow 🐈" and
			ret2_1 == "meow :3" and ret2_2 == "mrrow 🐈"
		)
	end
end)