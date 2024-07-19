### Race

utility function for getting the return from the first function
in an array to return

#### example
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
