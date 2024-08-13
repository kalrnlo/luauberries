--!native

-- warn
-- pure luau version of roblox's warn global

local function warn(...: unknown)
	print(`\27[0;33m{table.concat({ ... }, " ")}\27[0m`)
end

return warn