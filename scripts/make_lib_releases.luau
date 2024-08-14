
-- make lib releases
-- makes new releases for each lib thats changed

local impl_module_source_prop = require("impl_module_source_prop")
local DateTime = require("@lune/DateTime")
local diff_reader = require("diff_reader")
local process = require("@lune/process")
local serde = require("@lune/serde")
local packager = require("packager")
local libinfo = require("libinfo")
local summon = require("summon")
local fs = require("@lune/fs")

type ReleaseLibInfo = {
	latest_release_time: number,
	commits: { Commit },
	prs: { PRInfo },
	name: string,
}

type PRInfo = {
	author: string,
	title: string,
	num: number,
}

type Commit = {
	author: string,
	title: string,
	hash: string,
	date: number,
}

local GIT_LOG_PATTERN = "commit (%x+)\nAuthor: (.-) <.->\nDate:%s+(.-)\n\n%s+(.-)\n?\n"
local GIT_DATE_FORMAT = "(%w+) (%w+) (%d+) (%d+):(%d+):(%d+) (%d+) ([?%+%-]%d%d)(%d%d)"
local BASE_REPO_URL = "https://github.com/kalrnlo/rbxlibs"
local BASE_COMMIT_URL = `{BASE_REPO_URL}/commits/`
local BASE_PULL_URL = `{BASE_REPO_URL}/pull/`

local PULL_REQUESTS = serde.decode("json", summon("gh", "pr list --json author,mergedAt,files,title,number --limit 100 --state merged"))
local RELEASES = summon("gh", "release list --repo kalrnlo/rbxlibs --limit 500")
local LIBS_CHANGED = diff_reader.libs()
local ARGS = process.args

local RBXLIBS_CREATION_DATE = DateTime.fromUniversalTime({
	year = 2024, day = 24, month = 6, 
	hour = 8, minute = 0, second = 0,
}).unixTimestamp
local MONTHS = table.freeze({ 
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, 
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}) :: { [string]: number }

local LIB_LIST: { string } = if ARGS[1] == "all" then
		fs.readDir("libs")
	elseif #ARGS ~= 0 then
		table.move(ARGS, 1, #ARGS, #LIBS_CHANGED + 1, LIBS_CHANGED)
	else
		LIBS_CHANGED
local RELEASE_LIBS = table.create(#LIB_LIST) :: { ReleaseLibInfo }

-- local CREATE = roblox.Instance.new
local GMATCH = string.gmatch
local MATCH = string.match
local SUB = string.sub

local function parse_git_date(date: string): number
	-- git log date format: "Day Mon DD HH:MM:SS YYYY +-ZZZZ"
	local _, month, day, hour, minutes, seconds, year, zone_hours, zone_minutes = MATCH(date, GIT_DATE_FORMAT)
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

local function write_and_insert(t: { string }, path: string, contents: string | buffer)
	fs.writeFile(path, contents)
	table.insert(t, path)
end

impl_module_source_prop()

for index, lib in LIB_LIST do
	local pattern = `{lib} v%d+%.%d+%.%d+\t([^\t]+)\t{lib}%-v%d+%.%d+%.%d+\t(%S+)`
	local log = summon("git", `log --after {time} -- libs/{lib}`)
	local latest_release_time = RBXLIBS_CREATION_DATE
	local commits = {}

	for type, iso in GMATCH(RELEASES, pattern) do
		if type ~= "Draft" then
			local date = DateTime.fromIsoDate(iso).unixTimestamp

			if latest_release_time < date then
				latest_release_time = date
			end
		end
	end
	
	for hash, author, date, title in GMATCH(log, GIT_LOG_PATTERN) do
		table.insert(commits, {
			date = parse_git_date(date),
			author = author,
			title = title,
			hash = hash,
		})
	end

	RELEASE_LIBS[index] = {
		latest_release_time = latest_release_time,
		commits = commits,
		name = lib,
		prs = {},
	}
end

for index, pr in PULL_REQUESTS do
	local has_changed_a_release_lib: string

	for _, file in pr.files do
		local lib = MATCH(file.path, "^libs/([^/]+)") or MATCH(file.path, "^docs/([^/%.]+)")

		if lib then
			local pr_time = DateTime.fromIsoDate(pr.mergedAt).unixTimestamp
			local found_libinfo: ReleaseLibInfo
			
			for _, release_lib_info in RELEASE_LIBS do
				if 
					release_lib_info.name == lib and
					pr_time >= release_lib_info.latest_release_time 
				then
					found_libinfo = release_lib_info
					break
				end
			end

			if not found_libinfo then
				continue
			end

			local author_info = pr.author
			local author_name = author_info.name

			table.insert(found_libinfo.prs, {
				author = pr.author.login,
				title = pr.title,
				num = pr.number,
			})
			break
		end
	end
end

for _, release_libinfo in RELEASE_LIBS do
	local lib = release_libinfo.name
	local package_libinfo = packager.package(lib)
	local libinfo = libinfo(lib)
	local version = libinfo.version
	local base_file_name = package_libinfo.base_file_name
	local notes = { "## Whats changed" }
	local release_tag = `{lib}@{version}`
	local release_files = {}

	for _, pr in release_libinfo.prs do
		table.insert(notes, `* {pr.title} by @{pr.author} in {BASE_PULL_URL}{pr.num}`)
	end

	for _, commit in release_libinfo.commits do
		table.insert(notes, `* {commit.title} by @{commit.author} in {BASE_COMMIT_URL}{commit.hash}`)
	end

	fs.writeDir("dist")
	write_and_insert(release_files, `./dist/{base_file_name}.zip`, package_libinfo.zipped)
	write_and_insert(release_files, `./dist/{base_file_name}.rbxm`, package_libinfo.rbxm)

	if package_libinfo.has_deps then
		local base_deps_file_name = package_libinfo.base_file_name_with_deps

		write_and_insert(release_files, `./dist/{base_deps_file_name}.zip`, package_libinfo.zipped_with_deps)
		write_and_insert(release_files, `./dist/{base_deps_file_name}.rbxm`, package_libinfo.rbxm_with_deps)
	end

	summon("gh", `release create {release_tag} --title "{lib} v{version}" --notes "{table.concat(notes, "\n")}" --draft`)

	for _, path in release_files do
		summon("gh", `release upload {release_tag} {path} --clobber`)
	end
	fs.removeDir("dist")
end

fs.removeDir("libs_copy")
process.exit()