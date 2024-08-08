
local fs = require("@lune/fs")

local function PRINT_METADATA(path: string)
	local metadata = table.clone(fs.metadata(path))

	for key, value in metadata do
		if typeof(value) == "DateTime" then
			metadata[key] = value:formatLocalTime("%d/%m/%Y")
		end
	end
	print(metadata)
end

local function RECURSE(dir: string)
	for _, entry in fs.readDir(dir) do
		local entry_path = `{dir}/{entry}`
		PRINT_METADATA(entry_path)

		if fs.isDir(entry_path) then
			RECURSE(entry_path)
		end
	end
end

RECURSE("libs")
