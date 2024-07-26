# Race

Runs several functions at once, and returns the result of the function that completes first

```luau
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

print(result) -- "i return!"
```
