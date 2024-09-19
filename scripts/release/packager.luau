
-- packager
-- makes new releases for each lib thats changed

local require_pattern = require("../require_pattern")
local remove_from_end = require("../remove_from_end")
local iter_scripts = require("../iter_scripts")
local depgraph = require("../depgraph")
local roblox = require("@lune/roblox")
local modulify = require("modulify")
local license = require("license")
local libinfo = require("libinfo")
local fs = require("@lune/fs")
local zip = require("zip")

export type PackagedLibInfo = {
	base_file_name_with_deps: nil,
	base_file_name: string,
	zipped_with_deps: nil,
	rbxm_with_deps: nil,
	has_deps: false,
	version: string,
	zipped: string,
	rbxm: string,
} | {
	base_file_name_with_deps: string,
	zipped_with_deps: string,
	rbxm_with_deps: string,
	base_file_name: string,
	version: string,
	zipped: string,
	has_deps: true,
	rbxm: string,
}

local CACHED_PACKAGED_LIBS = {} :: { [string]: PackagedLibInfo }
local RBXMIFY = roblox.serializeModel
local MATCH = string.match
local GSUB = string.gsub

local function package_lib(lib: string): PackagedLibInfo
	local version = libinfo(lib).version
	local libdir = `libs_copy/{lib}`
	local depinfo = depgraph[lib]
	local has_deps = depinfo.has_deps

	local output_dir = lib
	local output_deps_dir = `{output_dir}-deps`
	local initdir = `{libdir}/init`
	local initdir_exists = fs.isDir(initdir)
	local initext = if initdir_exists then initdir else `{initdir}.luau`

	fs.writeDir(output_dir)

	if initdir_exists then
		fs.copy(initdir, output_dir, true)
	else
		fs.copy(initext, `{output_dir}/init.luau`, true)
	end

	local lib_module = modulify(lib)
	local rbxm = RBXMIFY({ lib_module })
	local zipped = zip(output_dir)
	local zipped_with_deps: string
	local rbxm_with_deps: string

	if has_deps then
		fs.writeDir(output_deps_dir)

		if initdir_exists then
			fs.copy(output_deps_dir, `{output_deps_dir}/{lib}`, true)
		else
			fs.copy(`{output_dir}/init.luau`, `{output_deps_dir}/{lib}.luau`, true)
		end
		local modules = { lib_module }

		for _, deplib in depinfo.deep do
			table.insert(modules, modulify(deplib))

			local dep_libdir = `libs_copy/{deplib}`
			local dep_initdir = `{dep_libdir}/init`
			local dep_initdir_exists = fs.isDir(dep_initdir)
			local dep_initext = if dep_initdir_exists then dep_initdir else `{dep_initdir}.luau`
			local dep_output_dir = `{output_deps_dir}/{deplib}`

			if dep_initdir_exists then
				fs.copy(dep_initext, dep_output_dir, true)
			else
				fs.copy(dep_initext, `{dep_output_dir}.luau`, true)
			end
		end

		zipped_with_deps = zip(output_deps_dir)
		rbxm_with_deps = RBXMIFY(modules)
		fs.removeDir(output_deps_dir)
	end

	local base_file_name = `{lib}-{version}`
	local packaged_libinfo = table.freeze({
		base_file_name_with_deps = `{base_file_name}-deps`,
		zipped_with_deps = zipped_with_deps,
		rbxm_with_deps = rbxm_with_deps,
		base_file_name = base_file_name,
		has_deps = has_deps :: any,
		version = version,
		zipped = zipped,
		rbxm = rbxm,
	}) :: PackagedLibInfo

	CACHED_PACKAGED_LIBS[lib] = packaged_libinfo
	fs.removeDir(output_dir)

	return packaged_libinfo
end

local packager = { package = package_lib }

function packager.bulk_package(libs: { string }): { [string]: PackagedLibInfo }
	local packaged_libs = {}

	for _, lib in libs do
		packaged_libs[lib] = package_lib(lib)
	end
	return table.freeze(packaged_libs)
end

do

	fs.copy("libs", "libs_copy", true)

	for _, lib in fs.readDir("libs_copy") do
		iter_scripts(`libs_copy/{lib}`, function(path, src)
			local hot_comments = {}

			local fixed_requires_src = GSUB(src, "(local%s+%w+%s*=%s*require%s*%(%-?%-?%-?[\"'`].-[\"'`]%))", function(line)
				local new_path = remove_from_end(MATCH(line, require_pattern), "/init")
				local variable = MATCH(line, "local%s+(%w+)%s*")
				return `local {variable} = require("{new_path}")`
			end)
			local stripped_hot_comments_src = GSUB(fixed_requires_src, "(%-%-!.-\n)", function(hot_comment)
				table.insert(hot_comments, hot_comment)
				return ""
			end)

			return `{table.concat(hot_comments)}\n{license}{stripped_hot_comments_src}`
		end)
	end

end

return table.freeze(packager)