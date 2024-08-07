--!native

-- task
-- a good enough pure luau version of roblox's task lib
-- that doesnt require wrapping ur whole script in a
-- task.spawn or anything

local function SPAWN<A..., R...>(
	thread_or_func: thread | (A...) -> R..., 
	...: A...
): thread
	if type(thread_or_func) == "thread" then
		coroutine.resume(thread_or_func, ...)
		return thread_or_func
	else
		local thread = coroutine.create(thread_or_func)
		coroutine.resume(thread, ...)
		return thread
	end
end

local function CANCEL(thread: thread)
	local success, result = coroutine.close(thread)

	if not success then
		error(`[TASK] could not cancel thread\n\terror: {result}`)
	end
end

local function WAIT(seconds: number?): number
	local start_time = os.clock()
	local end_time = start_time + (seconds or 1)
	local clock_time: number

	repeat
		clock_time = os.clock()
	until clock_time >= end_time
	return clock_time - start_time
end

local function DELAY<A..., R...>(
	seconds: number,
	thread_or_func: thread | (A...) -> R..., 
	...: A...
): thread
	local thread = SPAWN(function(
		seconds: number,
		thread_or_func: thread | (A...) -> R..., 
		...: A...
	)
		task.wait(seconds)

		if type(thread_or_func) == "thread" then
			coroutine.resume(thread_or_func, ...)
		else
			thread_or_func(...)
		end
	end, seconds, thread_or_func, ...)

	return thread
end

return table.freeze({
	cancel = CANCEL,
	spawn = SPAWN,
	defer = SPAWN,
	delay = DELAY,
	wait = WAIT,
})