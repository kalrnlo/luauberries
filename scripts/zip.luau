
-- zip
-- utility for zipping files within lune

local summon = require("summon")

local function zip(input: { string } | string, output: string, exclude: { string }?)
	local args: { string }

	if type(input) == "table" then
		args = table.move(input, 1, #input, 2, { output })
	else
		args = { "-r", output, input }

		if exclude then
			table.insert(args, "-x")
			table.move(exclude, 1, #exclude, 5, args)
		end
	end
	summon("zip", args)
end

return zip
