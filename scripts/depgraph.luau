--!optimize 2
--!native

-- dep graph
-- module for generating a dependency graph for all libraries

local fs = require("@lune/fs")

local REQUIRE_PATTERN = "\r\nlocal%s+%w+%s*=%s*require%s*%(%-?%-?%-?[\"'`](.-)[\"'`]%)"
local GRAPH = {} :: { [string]: { string } }
local LINE_PATTERN = "[^\r\n]+"
local GMATCH = string.gmatch
local MATCH = string.match
local SUB = string.sub

local function FIND_LIB_IN_RELATIVE_PATH(path: string): string?
	local fixed_path = if MATCH(path, "/init$") then SUB(path, 1, #path - 5) else path
	local found_lib = MATCH(fixed_path, "([^/]+)$")

	warn(fixed_path, found_lib)
	return if found_lib and GRAPH[found_lib] then
			found_lib
		else
			nil
end

local function find_deps(lib: string, dir: string, dependencies_tbl: { string })
	for _, entry in fs.readDir(dir) do
		local entry_path = `{dir}/{entry}`
		
		-- does the file have a .luau extention
		if MATCH(entry, "%.luau$") then
			local contents = fs.readFile(entry_path)
			print(`entry: {entry_path}`)
			print(contents)

			for require_path in GMATCH(contents, REQUIRE_PATTERN) do
				print(require_path)
				local deplib = FIND_LIB_IN_RELATIVE_PATH(require_path)
				
				if deplib and not table.find(dependencies_tbl, deplib) then
					table.insert(dependencies_tbl, deplib)
				end
			end
		elseif fs.isDir(entry_path) then
			find_deps(lib, entry_path, dependencies_tbl)
		end
	end
end

for _, lib in fs.readDir("libs") do
	GRAPH[lib] = {}
end

for lib, dependencies_tbl in GRAPH do
	find_deps(lib, `libs/{lib}`, dependencies_tbl)
end

for _, dependencies_tbl in GRAPH do
	table.freeze(dependencies_tbl)
end

print(GRAPH)
print(table.find(GRAPH["playerzone"], "character"))
print(table.find(GRAPH["Grouper"], "connector"))
print(table.find(GRAPH["connector"], "cross"))
print(table.find(GRAPH["Retryer"], "cross"))
print(table.find(GRAPH["race"], "cross"))
return table.freeze(GRAPH)