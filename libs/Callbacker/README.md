### Callbacker

Utility module for easily handling callbacks

#### example
```lua
local add_callback, run_callbacks = require("@kalrnlo/callbacker")

local callbacks = {}

add_callback(callbacks, function(foo: string, bar: number)
    print(foo, bar)
end)

run_callbacks(callbacks, "lol", 200)

```