
-- make lib releases
-- makes new releases for each lib thats changed

local process = require("@lune/process")
process.env.RUST_BACKTRACE = "full"

local DateTime = require("@lune/DateTime")
local diff_reader = require("diff_reader")
local process = require("@lune/process")
local build_rbxm = require("build_rbxm")
local roblox = require("@lune/roblox")
local modulify = require("modulify")
local depgraph = require("depgraph")
local libinfo = require("libinfo")
local summon = require("summon")
local fs = require("@lune/fs")
local zip = require("zip")

type Commit = {
	author: string,
	title: string,
	hash: string,
	date: number,
	url: string,
}

local GIT_LOG_PATTERN = "commit (%x+)\nAuthor: (.-) <.->\nDate:%s+(.-)\n\n%s+(.-)\n?\n"
local GIT_DATE_FORMAT = "(%w+) (%w+) (%d+) (%d+):(%d+):(%d+) (%d+) ([?%+%-]%d%d)(%d%d)"
local BASE_REPO_URL = "https://github.com/kalrnlo/rbxlibs"
local BASE_COMMIT_URL = `{BASE_REPO_URL}/commits/`

local RELEASES = summon("gh", { "release", "list", "--repo", "kalrnlo/rbxlibs", "--limit", "1000" })
local MONTHS = table.freeze({ 
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, 
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}) :: { [string]: number }
local BUILT_LIBS = {} :: { [string]: modulify.ModuleScript }
local LIBS_CHANGED = diff_reader.libs()

-- local CREATE = roblox.Instance.new
local GMATCH = string.gmatch
local MATCH = string.match
local SUB = string.sub

local function get_latest_release_time(lib: string): number
	local pattern = `{lib} v%d+%.%d+%.%d+\t([^\t]+)\t{lib}%-v%d+%.%d+%.%d+\t(%S+)`
	local latest_date = 0

	for type, iso in GMATCH(RELEASES, pattern) do
		if type ~= "Draft" then
			local date = DateTime.fromIsoDate(iso).unixTimestamp

			if latest_date < date then
				latest_date = date
			end
		end
	end
	return 0
end

local function parse_git_date(date: string): number
	-- git log date format: "Day Mon DD HH:MM:SS YYYY +-ZZZZ"
	local _, month, day, hour, minutes, seconds, year, zone_hours, zone_minutes = MATCH(date, GIT_DATE_FORMAT)
	print(month, day, hour, minutes, seconds, year, zone_hours, zone_minutes)
	local zone_minutes = tonumber(zone_minutes)
	local zone_hours = tonumber(zone_hours)
	local seconds = tonumber(seconds)
	local minutes = tonumber(minutes)
	local month = MONTHS[month]
	local year = tonumber(year)
	local hour = tonumber(hour)
	local day = tonumber(day)

	if 
		day and month and hour and minutes and seconds and 
		year and zone_hours and zone_minutes
	then
		local timestamp = os.time({
			min = minutes, sec = seconds, month = month, 
			day = day, year = year, hour = hour,
		})

		return timestamp - ((zone_hours * 3600) + (zone_minutes * 60))
	else
		error(`[GIT DATE] could not parse {date} as it wasnt in format "Day Mon DD HH:MM:SS YYYY +-ZZZZ"`)
	end
end

local function get_commits_after_time(lib: string, time: number): { Commit }
	local log = summon("git", { "log", "--after", tostring(time), "--", `libs/{lib}` })
	local commits = {}
	
	for hash, author, date, title in GMATCH(log, GIT_LOG_PATTERN) do
		table.insert(commits, {
			url = `{BASE_COMMIT_URL}{hash}`,
			date = parse_git_date(date),
			author = author,
			title = title,
			hash = hash,
		})
	end
	return commits
end

local args = table.clone(process.args)

-- with lune run, required scripts cant implement a property so
-- were doing it a jank way via an arg
local implprop_index = table.find(args, "implprop")

if implprop_index then
	table.remove(args, implprop_index)
	local SOURCES = {} :: {[roblox.Instance]: string}

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
end

if table.find(args, "all") then
	LIBS_CHANGED = fs.readDir("libs")
elseif #args ~= 0 then
	table.move(args, 1, #args, #LIBS_CHANGED + 1, LIBS_CHANGED)
end

local OUTPUT_DIR = "output"

if fs.isDir(OUTPUT_DIR) then
	fs.removeDir(OUTPUT_DIR)
end
fs.writeDir(OUTPUT_DIR)

local function get_or_create_module(lib: string): modulify.ModuleScript
	local built = BUILT_LIBS[lib]

	if built then 
		return built 
	else 
		local module = modulify(lib)
		BUILT_LIBS[lib] = module
		return module
	end
end

print(LIBS_CHANGED)

for _, lib in LIBS_CHANGED do
	local latest_release_time = get_latest_release_time(lib)
	local commits = get_commits_after_time(lib, latest_release_time)
	local libinfo = libinfo(lib)

	local version = libinfo.version

	local lib_output_dir = `{OUTPUT_DIR}/{lib}-{version}`
	local lib_output_dir_with_deps = `{lib_output_dir}-deps`
	local depinfo = depgraph[lib]
	local libdir = `libs/{lib}`
	local has_deps = depinfo.has_deps

	fs.writeDir(lib_output_dir)

	local initdir = `{libdir}/init`
	local initdir_exists = fs.isDir(initdir)
	local initext = if initdir_exists then initdir else `{initdir}.luau`

	if fs.isDir(initdir) then
		fs.copy(initdir, lib_output_dir, true)
	else
		fs.copy(initext, `{lib_output_dir}/init.luau`, true)
	end

	--zip(lib_output_dir, `{lib_output_dir}.zip`)
	local module = get_or_create_module(lib)
	local rbxm_with_deps: string

	fs.writeFile(`{lib_output_dir}.rbxm`, build_rbxm(module))

	if has_deps then
		fs.writeDir(lib_output_dir_with_deps)

		if initdir_exists then
			fs.copy(lib_output_dir, `{lib_output_dir_with_deps}/{lib}`, true)
		else
			fs.copy(`{lib_output_dir}/init.luau`, `{lib_output_dir_with_deps}/{lib}.luau`, true)
		end
		local modules = { module }

		for _, deplib in depinfo.deep do
			table.insert(modules, get_or_create_module(deplib))
			local deplibdir = `libs/{deplib}`
			local initdir = `{deplibdir}/init`
			local initdir_exists = fs.isDir(initdir)
			local initext = if initdir_exists then initdir else `{initdir}.luau`

			if fs.isDir(initdir) then
				fs.copy(initdir, `{lib_output_dir_with_deps}/{deplib}`, true)
			else
				fs.copy(initext, `{lib_output_dir_with_deps}/init.luau`, true)
			end
		end

		rbxm_with_deps = roblox.serializeModel(modules)
		fs.writeFile(`{lib_output_dir_with_deps}.rbxm`, rbxm_with_deps)
	end



end

process.exit()