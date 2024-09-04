# Cross

Utility for dealing with cross runtime shenanigans, covering the bear necessities

> [!NOTE]
> Cross adds the following globals if they don't already exist,
> `warn`, `task`, and `_RUNTIME`. Although these are the exact same as their counterpart globals in roblox's runtime.
> Except for `_RUNTIME` which is a string indicating the current runtime.
>
> Docs for [`task`](https://create.roblox.com/docs/reference/engine/libraries/task#warn) and [`warn`](ttps://create.roblox.com/docs/reference/engine/globals/RobloxGlobals) can be found on [`Roblox's Docs`](https://create.roblox.com/docs/reference/engine) although `task.synchronize` and `task.desynchronize` don't exist within cross

```luau
local cross = require("cross")

task.spawn(function()
	print("hey im a new global")
	warn("hey i am too!")
end)
```

## Types

### `Runtime`

```luau
type Runtime = "ROBLOX" | "LUNE" | "NONE"
```

## Methods

### `spawn`

Calls/resumes a function/coroutine immediately through the runtimes scheduler.

```luau
local thread = cross.spawn(function()
	print("im gonna yield! and you cant stop me mwhahaha")
	coroutine.yield()
	print("aw man u stopped me :(")
end)

cross.spawn(thread) -- aw man u stopped me :(
```

### `defer`

Calls/resumes a function/coroutine on the next resumption cycle.

> [!NOTE]
> In runtimes without a task library or a task global (or if you're running in pure luau). Cross defaults back to using [`spawn`](#spawn)


```luau
cross.defer(function()
	print("omg its the next cycle!")
end)
```

### `delay`

Calls/resumes a function/coroutine on the next resumption cycle after the given amount of time in seconds has elapsed.

```luau
cross.delay(2, function()
	print("i print roughly 2 seconds later!")
end)

print("first :3")
```

### `cancel`

Cancels a thread, preventing it from being resumed.

> [!DANGER]
> Unlike [`coroutine.close`](https://luau-lang.org/library#coroutine-library:~:text=function%20coroutine.close(co%3A%20thread)%3A%20(boolean%2C%20any%3F)), `cancel` does not return any values from the thread, and will error if the thread cannot be closed


```luau
local thread = cross.defer(function()
	print("omg its the next cycle!")
end)

cross.cancel(thread)
```

### `wait`

Yields the current thread until the next resumption cycle in which the given duration (in seconds) has passed, without throttling.

> [!WARNING]
> If the current runtime doesn't have a wait function in it (or if you're running in pure luau), cross uses a [`busy wait`](https://github.com/kalrnlo/rbxlibs/blob/main/libs/cross/wait.luau) impl

```luau
local start = os.clock()

cross.wait(6)
print(os.clock() - start) -- roughly 6 seconds
```


### `warn`

Behaves identically to Luau's [`print`](https://luau-lang.org/library#global-functions:~:text=function%20print(args%3A%20...any)) global, except the output is styled as a warning with yellow text.

```luau
cross.warn("meow", "mrrp", 20)
```
