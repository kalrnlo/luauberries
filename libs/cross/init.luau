--!native

-- cross
-- cross runtime utility

type Spawn = <A..., R...>(f: ((A...) -> (R...)) | thread, A...) -> thread

local IS_ROBLOX = Instance and Instance.new and game and game.Genre
local IS_LUNE = string.find(_VERSION, "Lune") ~= nil
-- putting paraentheses around require removes its magic function
-- so i nolonger will get type errors :3
local REQUIRE = (require)

local function PURE_SPAWN<A..., R...>(
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

return table.freeze({ 
	roblox = IS_ROBLOX,
	lune = IS_LUNE,

	purespawn = PURE_SPAWN,
	spawn = (if task then 
		task.spawn
	elseif IS_LUNE then 
		REQUIRE("@lune/task").spawn 
	else 
		PURE_SPAWN) :: Spawn,
})