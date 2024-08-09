
-- test runner
-- script for running tests for ci

local diff_to_tbl = require("diff_to_tbl")
local process = require("@lune/process")
local depgraph = require("depgraph")
local fs = require("@lune/fs")
local ansi = require("ansi")

local CHANGED_SET: { [string]: boolean }
local LIBS: { string }

if fs.isFile(".diff") then
	local diff = fs.readFile(".diff")
	LIBS, CHANGED_SET = diff_to_tbl(diff)

	for lib, deps in depgraph do
		if CHANGED_SET[lib] then
			continue
		end

		for _, dep in deps do
			if not CHANGED_SET[dep] then
				continue
			end
			table.insert(LIBS, lib)
			CHANGED_SET[lib] = true
					
			for search_lib, search_deps in depgraph do
				if table.find(search_deps, lib) then
					CHANGED_SET[search_lib] = true
					table.insert(LIBS, search_lib)
				end
			end
			break
		end
	end
else
	LIBS = fs.readDir("libs")
end

for _, lib in LIBS do
	local path = `libs/{lib}/test`
	local file_path = `{path}.luau`
	local real_path: string
	local contents: string

	if fs.isDir(path) then
		local init_path = `{path}/init.luau`

		if fs.isFile(init_path) then
			contents = fs.readFile(init_path)
			real_path = init_path
		else
			error(ansi.boldred(`LIBRARY {lib} HAS A TEST DIRECTORY WITH NO FILE CALLED "init.luau" IN IT`))
		end
	elseif fs.isFile(file_path) then
		contents = fs.readFile(file_path)
		real_path = file_path
	else
		continue
	end

	-- test not implemented and its just a placeholder as a reminder
	if #contents == 0 then
		continue
	end

	fs.writeFile(real_path, `{contents}\n\nassert(FINISH())\nprint()`)
	;(require)(`../{real_path}`)
	fs.writeFile(real_path, contents)
end

process.exit(0)