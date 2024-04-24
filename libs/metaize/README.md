### Metaize

Utility function for creating prototypes for classes

#### example
```lua
local metaize = require "@kalrnlo/metaize"

type class = {
    foo: (self: class, str: string) -> (),
    bar: (self: class, n: number) -> (),
}

local function foo(self: class, str: string)

end

local function bar(self: class, n: number)

end

-- metaize auto adds an __index key that points back to the prototype
-- and freezes the prototype class
local class_prototype = metaize {
    foo = foo,
    bar = bar,
}

```
