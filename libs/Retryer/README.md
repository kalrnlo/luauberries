### Retryer

Module for easily retrying functions

#### example
```lua
local retryer = require("@kalrnlo/retryer")

local function foo(n: number)
    return n + 1
end

-- delay between retrys, max retrys, function to retry, function args
local added = retryer.delay(10, 20, foo, 1)

-- max retrys, function to retry, function args
local other_added = retryer(20, foo, 1)
other_added -= 3


```