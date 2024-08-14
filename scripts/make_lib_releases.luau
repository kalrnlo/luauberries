
-- make lib releases
-- makes new releases for each lib thats changed

local process = require("@lune/process")
process.env.RUST_BACKTRACE = "full"

local impl_module_source_prop = require("impl_module_source_prop")
local DateTime = require("@lune/DateTime")
local diff_reader = require("diff_reader")
local process = require("@lune/process")
local packager = require("packager")
local libinfo = require("libinfo")
local summon = require("summon")
local fs = require("@lune/fs")

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

local RELEASES = summon("gh", "release list --repo kalrnlo/rbxlibs --limit 1000")
local MONTHS = table.freeze({ 
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, 
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}) :: { [string]: number }
local LIBS_CHANGED = diff_reader.libs()
local RBXLIBS_CREATION_DATE = DateTime.fromUniversalTime({
	year = 2024, day = 24, month = 6, 
	hour = 8, minute = 0, second = 0,
}).unixTimestamp
local RELEASE_LIBS: { string }
local ARGS = process.args

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
	return RBXLIBS_CREATION_DATE
end

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

local function get_commits_after_time(lib: string, time: number): { Commit }
	local log = summon("git", `log --after {time} -- libs/{lib}`)
	local commits = {}
	
	for hash, author, date, title in GMATCH(log, GIT_LOG_PATTERN) do
		table.insert(commits, {
			date = parse_git_date(date),
			author = author,
			title = title,
			hash = hash,
		})
	end
	return commits
end

local function get_pr_for_commit(commit: Commit): number?
	return tonumber(MATCH(commit.title, "Merge pull request #(%d+).-"))
end

RELEASE_LIBS = if table.find(ARGS, "all") then
		fs.readDir("libs")
	elseif #ARGS ~= 0 then
		table.move(ARGS, 1, #ARGS, #LIBS_CHANGED + 1, LIBS_CHANGED)
	else
		LIBS_CHANGED

impl_module_source_prop()

for _, lib in RELEASE_LIBS do
	local latest_release_time = get_latest_release_time(lib)
	local commits = get_commits_after_time(lib, latest_release_time)
	--local package_libinfo = packager.package(lib)
	local libinfo = libinfo(lib)

	for _, commit in commits do
		local pr = get_pr_for_commit(commit)

		if pr then
			print(pr)
		end
	end


end

process.exit()