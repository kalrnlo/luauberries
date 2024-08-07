--!native

-- callbacks
-- utility for handling callbacks

local cross = require("libs/cross")

local callbacks = {}

function callbacks.SPAWN<A...>(callbacks: { { (A...) -> () } }, ...: A...)
	for _, callback_info in callbacks do
		cross.spawn(callback_info[1], ...)
	end
end

function callbacks.CONNECTION<A...>(
	callbacks: { { (A...) -> () } },
	callback: (A...) -> ()
): () -> ()
	local info = table.freeze({ callback })
	table.insert(callbacks, info)

	return function()
		local index = table.find(callbacks, info)

		if index then
			if index ~= 1 then
				local len = #callbacks
				callbacks[index] = callbacks[len]
				callbacks[len] = nil
			else
				callbacks[1] = nil
			end
		end
	end
end

return table.freeze(callbacks)


