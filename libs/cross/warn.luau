--!native

-- warn
-- pure luau version of roblox's warn global

local function warn<A...>(...: A...)
	print(`\27[33;1m{table.concat({ ... }, " ")}\27[0m`)
end

return warn