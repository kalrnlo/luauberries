### Observer

A simple observer library for roblox

#### example
```lua
local observer = require("@kalrnlo/observer")

```

### api
#### methods

```lua
localtool(tag, callback, dont_add_existing)
```
- reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse
- pre_allocate_threads: a number of threads to preallocate, by defualt 2

```lua
character(callback, dont_add_existing)
```
- reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse
- pre_allocate_threads: a number of threads to preallocate, by defualt 2

```lua
tool(tag, callback, dont_add_existing)
```
- reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse
- pre_allocate_threads: a number of threads to preallocate, by defualt 2

```lua
tag(tag, callback, dont_add_existing)
```
- tag: boolean indicating whether or not the signal created should partake in thread reuse
- pre_allocate_threads: a number of threads to preallocate, by defualt 2

```lua
player(callback, dont_add_existing)
```
- reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse
- pre_allocate_threads: a number of threads to preallocate, by defualt 2
