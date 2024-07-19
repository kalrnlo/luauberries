
local task = require("@lune/task")
local race = require("race")

local result = race({
	function() 
		task.wait(5)
		return "i never return!"
	end,
	function()
		task.wait(3)
		return "i return!"
	end
})

assert(result == "i return!", `[FAILED] {result}`)
print(`[SUCCESS] {result}`)