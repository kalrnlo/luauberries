local testkit = require("../../testkit")
local playerzone = require("init")

local TEST, CASE, CHECK, FINISH = testkit.test()

local NOOP = function() end

TEST("player zone", function()
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
