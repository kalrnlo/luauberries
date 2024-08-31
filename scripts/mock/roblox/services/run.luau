
-- run
-- implements a mock run service for lune

local signal = require("../script_signal")
local task = require("@lune/task")
local impl = require("../impl")

local POST_SIM = signal()
local POST_SIM_CONNECTIONS = POST_SIM.Connections

task.spawn(function()
	local START = os.clock()

	while true do
		for _, f in POST_SIM_CONNECTIONS do
			task.defer(f, os.clock() - START)
			START = os.clock()
		end
		-- do not remove the wait otherwise ur gonna be fired because tests no workey
		task.wait()
	end
end)

return impl("RunService")
	:rprop("PostSimulation", POST_SIM)
	:rprop("Heartbeat", POST_SIM)