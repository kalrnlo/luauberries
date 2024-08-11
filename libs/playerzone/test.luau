local testkit = require("../../testkit")
-- local playerzone = require("init")

local TEST, CASE, CHECK, FINISH = testkit.test()

local NOOP = function() end

TEST("player zone", function()
	-- cannot actually run this test rn, because of the game global not being set
	-- because it cant be set because of a lune bug :(
	if true then
		return
	end

	do CASE("create")
		local zone = playerzone.create({
			cframe = CFrame.identity,
			size = Vector3.new(4, 5, 4),
			callback = NOOP,
			type = nil,
		})
	end

	do CASE("insert")
		
	end

	do CASE("remove")
		
	end

	do CASE("detect")
		
	end
end)
