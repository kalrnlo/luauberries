local testkit = require("../../testkit")
local leventine = require("leventine")

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("leventine", function()
	do CASE("score_32")
		CHECK(
			leventine.score("hi hello im meowing so much rn", "and IM A SERTIFIED MEOW HATER :(") == 27
		)
	end

	do CASE("score_32_sensitive")
		CHECK(
			leventine.score("hi hello im meowing so much rn", "and IM A SERTIFIED MEOW HATER :(", true) == 30
		)
	end

	do CASE("score_x")
		
	end

	do CASE("score_x_sensitive")
		
	end

	do CASE("map")
		
	end

	do CASE("map_min_score")
		
	end

	do CASE("map_case_sensitive")
		
	end

	do CASE("closest")
		
	end

	do CASE("closest_case_sensitive")
		
	end

	do CASE("has_match")
		
	end

	do CASE("has_match_sensitive")
		
	end
end)

if not FINISH() then error(nil, 0) end
