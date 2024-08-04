
-- release
-- creates rbxms and files or folders for release

local sort_descending = require("sort_descending")
local create_export = require("create_export")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local license = require("license")
local fs = require("@lune/fs")

type ModuleScript = roblox.Instance & {
	Source: string
}

local SOURCES = {} :: { [roblox.Instance]: string }
local CREATE_INSTANCE = roblox.Instance.new

local RBXLIBS_MODULE = CREATE_INSTANCE("ModuleScript")
local RBXLIBS_MODULE_REQUIRES = {} :: { string }
local RBXLIBS_MODULE_TYPES = {} :: { string }
local RBXLIBS_MODULE_RET = {} :: { string }
RBXLIBS_MODULE.Name = "rbxlibs"

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

local function FIND_AND_REMOVE_FILES_WITH_EXT(files: { string }, ext: string): boolean
	for index, filename in files do
		if ENDS_WITH(filename, ext) then
			table.remove(files, index)
			return true
		end
	end

	return false
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
			module = MAKE_NESTED_MODULE(libname, name, path, fs.readDir(path))
		else
			module = MAKE_MODULE_FROM_LUAU_FILE(name, fs.readFile(path))
		end

		module.Parent = parent
	end

	return parent :: any
end

local function CREATE_MODULE(libname: string, luau_entries: { string }): ModuleScript
	local root = `libs/{libname}`
	return if #luau_entries == 1 then
			MAKE_MODULE_FROM_LUAU_FILE(libname, fs.readFile(`{root}/init.luau`))
		else
			MAKE_NESTED_MODULE(libname, libname, root, table.clone(luau_entries))
end

local function ADD_TO_FULL_RBXM(libname: string, module: ModuleScript)
	local exported_types = create_export(libname, module.Source)
	local module_clone = module:Clone()
	module_clone.Parent = RBXLIBS_MODULE

	if #exported_types ~= 0 then
		table.insert(RBXLIBS_MODULE_TYPES, exported_types)
	end

	table.insert(RBXLIBS_MODULE_REQUIRES, `local {libname} = require(script:WaitForChild("{libname}"))\n`)
	table.insert(RBXLIBS_MODULE_RET, `\n\t{libname} = {libname},`)
end

local function PACK_INTO_RBXM(instance: roblox.Instance): string
	return roblox.serializeModel({ instance })
end

roblox.implementProperty(
	"ModuleScript", "Source", function(module)
		return SOURCES[module] or ""
	end, function(module, new_val)
		if type(new_val) == "string" then
			SOURCES[module] = new_val
		else
			error("property source must be of type string!")
		end
	end
)

fs.writeDir("output")
fs.writeFile(".darklua.json", serde.encode("json", {
	rules = {
		{
			rule = "convert_require",
     		current = {
				name = "path",
        		module_folder_name = "init",
      		},
      		target = "roblox",
		}
	}
}, true))

for _, libname in fs.readDir("libs") do
	local root = `libs/{libname}`
	local entries = fs.readDir(root)

	local readme_index = table.find(entries, "README.md")
	local package_path = `{root}/package.json`
	local output_root = `output/{libname}`

	if readme_index then
		table.remove(entries, readme_index)
	end

	repeat
		local has_test_entries = FIND_AND_REMOVE_FILES_WITH_EXT(entries, ".test.luau")
	until not has_test_entries

	local luau_entries = table.clone(entries)

	repeat
		local has_ts_type_defs = FIND_AND_REMOVE_FILES_WITH_EXT(luau_entries, ".d.ts")
	until not has_ts_type_defs

	repeat
		local has_json = FIND_AND_REMOVE_FILES_WITH_EXT(luau_entries, ".json")
	until not has_json

	local module = CREATE_MODULE(libname, luau_entries)
	local contents = table.create(#luau_entries)
	local rbxm = PACK_INTO_RBXM(module)

	fs.writeDir(output_root)
	fs.writeFile(`{output_root}/{libname}.rbxm`, PACK_INTO_RBXM(module))
	ADD_TO_FULL_RBXM(libname, module)

	if #luau_entries == 1 then
		fs.copy(`{root}/init.luau`, `{output_root}/{libname}.luau`, true)
	else
		local entries_root = `{output_root}/{libname}`
		fs.writeDir(entries_root)

		for index, name in luau_entries do
			fs.copy(`{root}/{name}`, `{entries_root}/{name}`, true)
		end
	end

	if fs.isFile(package_path) then
		
		-- TODO: upload to npm for roblox ts nerds
	end
end

sort_descending(RBXLIBS_MODULE_REQUIRES)
sort_descending(RBXLIBS_MODULE_TYPES)
sort_descending(RBXLIBS_MODULE_RET)

RBXLIBS_MODULE.Source = `\n-- rbxlibs\n-- a collection of libraries for luau and roblox\n-- github: https://github.com/kalrnlo/rbxlibs\n-- docs: https://libs.luau.lol\n\n{license}\n{table.concat(RBXLIBS_MODULE_REQUIRES)}\n{table.concat(RBXLIBS_MODULE_TYPES, "\n\n")}\n\nreturn table.freeze({"{"}{table.concat(RBXLIBS_MODULE_RET)}{"\n}"})`

fs.writeDir("output/libs")
fs.writeFile("output/libs/libs.rbxm", PACK_INTO_RBXM(RBXLIBS_MODULE))