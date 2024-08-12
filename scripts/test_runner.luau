
-- test runner
-- script for running tests for ci

local diff_reader = require("diff_reader")
local process = require("@lune/process")
local depgraph = require("depgraph")
local task = require("@lune/task")
local fs = require("@lune/fs")
local ansi = require("ansi")

local function get_libs_to_test(): { string }
	local args = process.args

	if #args ~= 0 then
		return args
	elseif fs.isFile(".diff") then
		if diff_reader.scripts() then
			return fs.readDir("libs")
		end
		local libs, changed_set = diff_reader.libs()
	
		for _, lib in libs do
			for _, libdep in depgraph[lib].deep do
				if not changed_set[libdep] then
					changed_set[libdep] = true
					table.insert(libs, libdep)
				end
			end
		end

		return libs
	else
		return fs.readDir("libs")
	end
end

for _, lib in get_libs_to_test() do
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
	-- require is no longer relative if its called within a pcall??
	local success, responce = pcall(require, real_path)
	fs.writeFile(real_path, contents)

	if not success then
		task.spawn(error, responce)
		process.exit(1)
	end
end

process.exit(0)