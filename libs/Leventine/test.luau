local testkit = require("../../testkit")
local leventine = require("init")

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

	do CASE("has_match_false")
		
	end

	do CASE("has_match_sensitive_false")
		
	end

	do CASE("has_match_true")
		
	end

	do CASE("has_match_sensitive_true")
		
	end
end)