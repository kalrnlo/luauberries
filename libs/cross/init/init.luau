--!nocheck
--!native
--!nolint

-- cross
-- basic cross runtime utility, covering the bear nessisities

-- darklua doesnt like "task" and "warn"
local cross_task = require("./task")
local cross_warn = require("./warn")

type Runtime = "ROBLOX" | "LUNE" | "NONE"

local RUNTIME: Runtime = if game and game.ClassName == "DataModel" and game.GraphicsQualityChangeRequest then
		"ROBLOX"
	elseif string.find(_VERSION, "Lune") then
		"LUNE"
	else
		"NONE"

local WARN: typeof(cross_warn) = warn or cross_warn

local TASK: typeof(cross_task) = if task then 
		task 
	elseif RUNTIME == "LUNE" then 
		(require)("@lune/task") 
	else 
		cross_task

do

	local function SET_G(key: string, value: unknown)
		if not _G[key] then
			_G[key] = value
		end
	end

	if not _RUNTIME then
		SET_G("_RUNTIME", RUNTIME)
		_RUNTIME = RUNTIME
	end

	if not warn then
		SET_G("warn", WARN)
		warn = WARN
	end

	if not task then
		SET_G("task", TASK)
		task = TASK
	end

end

return table.freeze({
	cancel = TASK.cancel,
	spawn = TASK.spawn,
	defer = TASK.defer,
	delay = TASK.delay,
	wait = TASK.wait,
	warn = WARN,

	runtime = RUNTIME,
})