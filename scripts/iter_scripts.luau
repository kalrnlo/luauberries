
-- iter scripts
-- recursively iterates over every luau file in a directory
-- and calls a callback that can then optionally overwrite the file

local iter_dir = require("./iter_dir")
local ends_with = require("ends_with")

local function iter_scripts(dir: string, f: (path: string, src: string) -> string?)
	iter_dir(dir, function(info)
		local path = info.path

		if ends_with(path, ".luau") then
			local new_src = f(path, info.file)

			if new_src then
				return {
					file = new_src
				}
			end
		end
		return
	end)
end

return iter_scripts
