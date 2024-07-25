### Signal

A pure Luau signal implementation, based on LemonSignal & robloxs signal-lua. With thread reuse as an option that can be used with the constructors.

#### example
```luau
local signal = require("@kalrnlo/Signal")

local regular_signal, fire = signal.create()

regular_signal:subscribe(function(...)
    print("signal was fired! wahoo!!", ...)
end)

fire("foo", "bar")

local value_signal, set = signal.value(10)

value_signal:once(function(val)
    print("i only print the next time this updates!", val)
end)

set(20)
set(30)
```

### api
#### constructors

```lua
create(reuse_threads, pre_allocate_threads)
```
- reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse
- pre_allocate_threads: a number of threads to preallocate, by defualt 2

```lua
value<value>(value, reuse_threads, pre_allocate_threads)
```
- ```note: value signals only fire their connections if the new value is different from the old value```
- value: the starting value for the value signal, value signals are diffrent in that they store a singular value, and the fire function is replaced with a set function to set the value
- reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse
- pre_allocate_threads: a number of threads to preallocate, by defualt 2

#### methods

```lua
signal:subscribe(callback)
```
- callback: a function that runs whenever the signal fires, with paramters that are the signals values

```lua
signal:wait()
```
Yields the current thread, and resumes the current thread with the values when from the signal is fired next

```lua
signal:once(callback)
```
Same as ```signal:subscribe()```, except for the fact it disconnects the callback after the next time the signal is fired

#### properties
```lua
signal.connections
```
An array of all of the connections the signal has, including threads for that called ```signal:Wait()``` and are waiting to be resumed the next time the signal is fired

```lua
signal.thread_pool
```
```note: this is exclusive to reuse signals only```

An array holding all of the threads that are currently unused that are pre-allocated for the reuse signal

```lua
signal.value
```
```note: this is exclusive to value signals only```

The current value stored by the value signal
