
-- test runner
-- script for running tests for ci

local diff_reader = require("diff_reader")
local mock_roblox = require("mock/roblox")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local depgraph = require("depgraph")
local task = require("@lune/task")
local fs = require("@lune/fs")
local ansi = require("ansi")

local function get_libs_to_test(): { string }
	local args = process.args
	local first_arg = args[1]
	local is_release = first_arg == "release"
	local args_len = #args

	if first_arg == "all" or not fs.isFile(".diff") then
		return fs.readDir("libs")
	elseif args_len > 1 or not is_release then
		return args
	elseif diff_reader.scripts() then
		return fs.readDir("libs")
	end
	local libs, changed_set = diff_reader.libs()

	if is_release then
		args[1] = args[args_len]
		args[args_len] = nil
		table.move(args, 1, args_len - 1, #libs + 1, libs)

		for _, lib in args do
			changed_set[lib] = true
		end
	end

	for lib, depinfo in depgraph do
		for _, libdep in depgraph[lib].deep do
			if changed_set[libdep] then
				changed_set[lib] = true
				table.insert(libs, lib)
				break
			end
		end
	end

	return libs
end

do
	-- https://github.com/lune-org/lune/issues/236
	local part = roblox.Instance.new("Part")

	pcall(function(part: { [string]: any })
		part.Shutdown = 10
	end, part)
	mock_roblox()
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