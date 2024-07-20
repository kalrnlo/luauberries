
local process = require("@lune/process")
local fs = require("@lune/fs")

local paths = fs.readDir("./libs")

for _, path in paths do
	print(path)
	process.spawn(`pesde publish -d "./libs/{path}"`)
end
