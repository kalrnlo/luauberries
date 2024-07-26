# Race

Runs several functions at once, and returns the result of the function that completes first

```luau
local task = require("@lune/task")
local race = require("race")

local result = race({
	function(str: string) 
		task.wait(5)
		return `{str}! i never return 🥲`
	end,
	function(str: string)
		task.wait(3)
		return `{str}! i return!`
	end
}, "yay")

print(result) -- "yay! i return!"
```
