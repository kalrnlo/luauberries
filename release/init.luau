
-- release
-- creates rbxms and files or folders for release

local sort_descending = require("sort_descending")
local create_export = require("create_export")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local license = require("license")
local fs = require("@lune/fs")

type ModuleScript = roblox.Instance & {
	Source: string
}

local SOURCES = {} :: { [roblox.Instance]: string }
local CREATE_INSTANCE = roblox.Instance.new

local RBXLIBS_MODULE = CREATE_INSTANCE("ModuleScript")
local RBXLIBS_MODULE_STR_REQUIRES = {} :: { string }
local RBXLIBS_MODULE_RBX_REQUIRES = {} :: { string }
local RBXLIBS_MODULE_TYPES = {} :: { string }
local RBXLIBS_MODULE_RET = {} :: { string }
RBXLIBS_MODULE.Name = "rbxlibs"

local LIB_TS_OUTPUT = "output/ALL_LIBS/typescript"
local LIB_LUAU_OUTPUT = "output/ALL_LIBS/luau"
local DARKLUA_OUTPUT_DIR = "darklua-output"

local function PACK_INTO_RBXM(instance: roblox.Instance): string
	return roblox.serializeModel({ instance })
end

local function ENDS_WITH(str: string, ends_with: string): boolean
	return string.sub(str, #str - (#ends_with - 1)) == ends_with
end

local function REMOVE_FROM_END(str: string, ends_with: string): string
	return if ENDS_WITH(str, ends_with) then 
			string.sub(str, 1, #str - #ends_with) 
		else 
			str
end

local function MAKE_MODULE_FROM_LUAU_FILE(name: string, data: string): ModuleScript
	local module = CREATE_INSTANCE("ModuleScript")
	module.Name = REMOVE_FROM_END(name, ".luau")
	module.Source = data
	return module
end

local function FIND_ENTRY_WITH_EXT(entries: { string }, ext: string): number?
	for index, entry_name in entries do
		if ENDS_WITH(entry_name, ext) then
			return index
		end
	end
	return nil
end

local function FIND_AND_REMOVE_ENTRIES_WITH_EXT(entries: { string }, ext: string)
	local index = FIND_ENTRY_WITH_EXT(entries, ext)	

	while index do
		table.remove(entries, index)
		index = FIND_ENTRY_WITH_EXT(entries, ext)
	end
end

local function MAKE_NESTED_MODULE(libname: string, name: string, root: string, entries: { string }): ModuleScript
	local init_file_index = table.find(entries, "init.luau")
	local parent: roblox.Instance

	if init_file_index then
		table.remove(entries, init_file_index)
		parent = MAKE_MODULE_FROM_LUAU_FILE(name, fs.readFile(`{root}/init.luau`))
	else
		parent = CREATE_INSTANCE("Folder") :: any
		parent.Name = name 
	end
		
	for index, name in entries do
		local path = `{root}/{name}`
		local module: roblox.Instance

		if fs.isDir(path) then
			local path_entries = fs.readDir(path)

			FIND_AND_REMOVE_ENTRIES_WITH_EXT(path_entries, ".d.ts")
			FIND_AND_REMOVE_ENTRIES_WITH_EXT(path_entries, ".json")
			module = MAKE_NESTED_MODULE(libname, name, path, path_entries)
		else
			module = MAKE_MODULE_FROM_LUAU_FILE(name, fs.readFile(path))
		end

		module.Parent = parent
	end

	return parent :: any
end

local function CREATE_MODULE(libname: string, luau_entries: { string }): ModuleScript
	local lib_dir = `libs/{libname}`

	if fs.isDir(DARKLUA_OUTPUT_DIR) then
		fs.removeDir(DARKLUA_OUTPUT_DIR)
	end
	fs.writeDir(DARKLUA_OUTPUT_DIR)

	-- converting string requires for rbxms
	local result = process.spawn("darklua", { "process", lib_dir, DARKLUA_OUTPUT_DIR })
	local module_dir = if result.ok then DARKLUA_OUTPUT_DIR else lib_dir

	return if #luau_entries == 1 then
		MAKE_MODULE_FROM_LUAU_FILE(libname, fs.readFile(`{module_dir}/init.luau`))
	else
		MAKE_NESTED_MODULE(libname, libname, module_dir, table.clone(luau_entries))
end

local function CREATE_RBXM(libname: string, luau_entries: { string }): string
	local module = CREATE_MODULE(libname, luau_entries)
	local exported_types = create_export(libname, module.Source)
	local module_clone = module:Clone()
	module_clone.Parent = RBXLIBS_MODULE

	if #exported_types ~= 0 then
		table.insert(RBXLIBS_MODULE_TYPES, exported_types)
	end

	table.insert(RBXLIBS_MODULE_RBX_REQUIRES, `local {libname} = require(script:WaitForChild("{libname}"))\n`)
	table.insert(RBXLIBS_MODULE_STR_REQUIRES, `local {libname} = require("{libname}")\n`)
	table.insert(RBXLIBS_MODULE_RET, `\n\t{libname} = {libname},`)
	return PACK_INTO_RBXM(module)
end

local function WRITE_LIB_TO_OUTPUT_DIR(output_dirname: string, all_libs_dir: string, libname: string, entries: { string })
	local entries_root = `output/{libname}/{output_dirname}`
	local root = `libs/{libname}`
	fs.writeDir(entries_root)

	for index, name in entries do
		fs.copy(`{root}/{name}`, `{entries_root}/{name}`, true)
	end
	fs.copy(entries_root, `{all_libs_dir}/{libname}`, true)
end

roblox.implementProperty(
	"ModuleScript", "Source", 
	function(module)
		return SOURCES[module] or ""
	end,
	function(module, new_val)
		if type(new_val) == "string" then
			SOURCES[module] = new_val
		else
			error("property source must be of type string!")
		end
	end
)

fs.writeDir("output")
fs.writeDir("output/ALL_LIBS")
fs.writeDir(LIB_LUAU_OUTPUT)
fs.writeDir(LIB_TS_OUTPUT)

for _, libname in fs.readDir("libs") do
	local libdir = `libs/{libname}`
	local entries = fs.readDir(libdir)

	local has_ts_type_defs = FIND_ENTRY_WITH_EXT(entries, ".d.ts") ~= nil
	local readme_index = table.find(entries, "README.md")
	local output_root = `output/{libname}`

	if readme_index then
		table.remove(entries, readme_index)
	end

	FIND_AND_REMOVE_ENTRIES_WITH_EXT(entries, ".test.luau")
	FIND_AND_REMOVE_ENTRIES_WITH_EXT(entries, ".toml")
	FIND_AND_REMOVE_ENTRIES_WITH_EXT(entries, ".yaml")
	FIND_AND_REMOVE_ENTRIES_WITH_EXT(entries, ".yml")

	local luau_entries = table.clone(entries)

	fs.writeDir(output_root)

	if has_ts_type_defs then
		WRITE_LIB_TO_OUTPUT_DIR("typescript", LIB_TS_OUTPUT, libname, entries)
		FIND_AND_REMOVE_ENTRIES_WITH_EXT(luau_entries, ".d.ts")
		FIND_AND_REMOVE_ENTRIES_WITH_EXT(luau_entries, ".json")

		local package_path = `{libdir}/package.json`

		if fs.isFile(package_path) then
		
			-- TODO: upload to npm for roblox ts nerds
		end
	end

	WRITE_LIB_TO_OUTPUT_DIR("luau", LIB_LUAU_OUTPUT, libname, luau_entries)
	fs.writeFile(`{output_root}/{libname}.rbxm`, CREATE_RBXM(libname, luau_entries))
end

sort_descending(RBXLIBS_MODULE_RBX_REQUIRES)
sort_descending(RBXLIBS_MODULE_STR_REQUIRES)
sort_descending(RBXLIBS_MODULE_TYPES)
sort_descending(RBXLIBS_MODULE_RET)

local function CREATE_RBXLIBS_MODULE_SOURCE(requires: { string }): string
	return `\
-- rbxlibs\
-- a collection of libraries for luau and roblox\
-- github: https://github.com/kalrnlo/rbxlibs\
-- docs: https://libs.luau.lol\
\
{license}\
{table.concat(requires)}\
{table.concat(RBXLIBS_MODULE_TYPES, "\n\n")}\
\
return table.freeze({"{"}{table.concat(RBXLIBS_MODULE_RET)}{"\n}"})`
end

RBXLIBS_MODULE.Source = CREATE_RBXLIBS_MODULE_SOURCE(RBXLIBS_MODULE_RBX_REQUIRES)
fs.writeFile("output/ALL_LIBS/rbxlibs.rbxm", PACK_INTO_RBXM(RBXLIBS_MODULE))
fs.writeFile("output/ALL_LIBS/luau/init.luau", CREATE_RBXLIBS_MODULE_SOURCE(RBXLIBS_MODULE_STR_REQUIRES))