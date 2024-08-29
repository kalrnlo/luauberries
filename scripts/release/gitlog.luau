
-- gitlog
-- gets the gitlog after a unixtimestamp for a library

local first_release_time = require("first_release_time")
local summon = require("../summon")

export type Commit = {
	author: string,
	title: string,
	hash: string,
	date: number,
}

local GIT_LOG_PATTERN = "commit (%x+)\nAuthor: (.-) <.->\nDate:%s+(.-)\n\n%s+(.-)\n?\n"
local GIT_DATE_FORMAT = "(%w+) (%w+) (%d+) (%d+):(%d+):(%d+) (%d+) ([?%+%-]%d%d)(%d%d)"
local MONTHS = table.freeze({ 
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, 
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}) :: { [string]: number }

local GMATCH = string.gmatch
local MATCH = string.match

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

local function gitlog(lib: string, time: number?): { Commit }
	local log = summon("git", `log --after {time or first_release_time} -- libs/{lib}`)
	local commits = {}

	for hash, author, date, title in GMATCH(log, GIT_LOG_PATTERN) do
		table.insert(commits, table.freeze({
			date = parse_git_date(date),
			author = author,
			title = title,
			hash = hash,
		}))
	end
	
	return commits
end

return gitlog