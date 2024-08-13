
-- modulify
-- utility for converting a library into a module script instance

local remove_from_end = require("remove_from_end")
local process = require("@lune/process")
local ends_with = require("ends_with")
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

export type ModuleScript = roblox.Instance & {
	ClassName: "ModuleScript",
	Source: string
}

export type Folder = roblox.Instance & {
	ClassName: "Folder",
}

local SOURCES = {} :: {[roblox.Instance]: string}
local CREATE = roblox.Instance.new :: typeof(roblox.Instance.new) & 
	((className: "ModuleScript") -> ModuleScript) & 
	((className: "Folder") -> Folder)
local DARKLUA_OUTPUT_DIR = "darklua_output"
local MATCH = string.match

local function from_file(name_or_path: string, src: string?): ModuleScript
	local fixed_path = if ends_with(name_or_path, "init.luau") then
		remove_from_end(name_or_path, "/init.luau")
	else 
		remove_from_end(name_or_path, ".luau")
	local src = src or fs.readFile(name_or_path)

	local module = CREATE("ModuleScript")
	module.Name = MATCH(fixed_path, "([^/]-)$")
	module.Source = src
	return module
end

local function from_dir(name: string, root_path: string): ModuleScript
	local entries = fs.readDir(root_path)
	local init_file_index = table.find(entries, "init.luau")
	local parent: roblox.Instance

	if init_file_index then
		table.remove(entries, init_file_index)
		parent = from_file(name, fs.readFile(`{root_path}/init.luau`))
	else
		parent = CREATE("Folder") :: any
		parent.Name = name 
	end
		
	for index, name in entries do
		local path = `{root_path}/{name}`

		if ends_with(name, ".luau") then
			from_file(name, fs.readFile(path)).Parent = parent
		elseif fs.isDir(path) then
			from_dir(name, path).Parent = parent
		end
	end

	return parent :: any
end

local function modulify(lib: string): ModuleScript
	local libdir = `libs/{lib}`
	local initdir = `{libdir}/init`
	local initdir_exists = fs.isDir(initdir)

	if fs.isDir(DARKLUA_OUTPUT_DIR) then
		fs.removeDir(DARKLUA_OUTPUT_DIR)
	end
	fs.writeDir(DARKLUA_OUTPUT_DIR)

	local lib_init_path = if initdir_exists then initdir else `{initdir}.luau`
	-- darklua doesnt support function attributes currently, so it'll fail if it runs into one
	-- so im just having it output the rbxm using a string requires if it fails
	local result = process.spawn("darklua", { "process", lib_init_path, DARKLUA_OUTPUT_DIR })
	local result_path = if result.ok then DARKLUA_OUTPUT_DIR else libdir
	print(result.ok, result.stderr)

	return if initdir_exists then
		from_dir(lib, result_path)
	else
		from_file(lib, fs.readFile(`{result_path}/init.luau`))
end

return modulify