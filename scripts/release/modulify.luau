
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

local CREATE = roblox.Instance.new :: typeof(roblox.Instance.new) & 
	((className: "ModuleScript") -> ModuleScript) & 
	((className: "Folder") -> Folder)
local CACHED_MODULES = {} :: { [string]: ModuleScript }
local DARKLUA_OUTPUT_DIR = "darklua_output"
local MATCH = string.match

local function FROM_FILE(name_or_path: string, src: string?): ModuleScript
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

local function FROM_DIR(name: string, root_path: string): ModuleScript
	local entries = fs.readDir(root_path)
	local init_file_index = table.find(entries, "init.luau")
	local parent: roblox.Instance

	if init_file_index then
		table.remove(entries, init_file_index)
		parent = FROM_FILE(name, fs.readFile(`{root_path}/init.luau`))
	else
		parent = CREATE("Folder") :: any
		parent.Name = name 
	end
		
	for index, name in entries do
		local path = `{root_path}/{name}`

		if ends_with(name, ".luau") then
			FROM_FILE(name, fs.readFile(path)).Parent = parent
		elseif fs.isDir(path) then
			FROM_DIR(name, path).Parent = parent
		end
	end

	return parent :: any
end

local function modulify(lib: string): ModuleScript
	local cached_module = CACHED_MODULES[lib]

	if cached_module then
		return cached_module
	end

	if fs.isDir(DARKLUA_OUTPUT_DIR) then
		fs.removeDir(DARKLUA_OUTPUT_DIR)
	end
	fs.writeDir(DARKLUA_OUTPUT_DIR)

	local libdir = `libs_copy/{lib}`
	local initdir = `{libdir}/init`
	local initdir_exists = fs.isDir(initdir)
	local lib_init_path = if initdir_exists then initdir else `{initdir}.luau`
	-- darklua doesnt support function attributes currently, so it'll fail if it runs into one
	-- so im just having it output the rbxm using a string requires if it fails
	local result = process.spawn("darklua", { "process", lib_init_path, DARKLUA_OUTPUT_DIR })
	local result_path = if result.ok then DARKLUA_OUTPUT_DIR else libdir
	local module = if initdir_exists then
			FROM_DIR(lib, result_path)
		else
			FROM_FILE(lib, fs.readFile(`{result_path}/init.luau`))
	
	if not result.ok then
		warn(result.stderr)
	end

	CACHED_MODULES[lib] = module
	return module
end

do
	if fs.isDir(DARKLUA_OUTPUT_DIR) then
		fs.removeDir(DARKLUA_OUTPUT_DIR)
	end
	fs.writeDir(DARKLUA_OUTPUT_DIR)
end

return modulify