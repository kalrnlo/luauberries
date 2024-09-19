
-- pull requests
-- util for getting pull requests after a unix timestamp

local first_release_time = require("first_release_time")
local datetime = require("@lune/datetime")
local serde = require("@lune/serde")
local summon = require("../summon")
local fs = require("@lune/fs")

export type PullRequestInfo = {
	merged_at: number,
	author: string,
	title: string,
	num: number,
}

local PULL_REQUESTS = serde.decode("json", summon("gh", "pr list --json author,mergedAt,files,title,number --limit 100 --state merged"))
local LIBS_TO_PRS = {} :: { [string]: { PullRequestInfo } }
local MATCH = string.match

local function get_after_time(lib: string, prs: { PullRequestInfo }, time: number): { PullRequestInfo }
	local prs_after_time = {}

	for _, pr in prs do
		if pr.merged_at > time then
			table.insert(prs_after_time, pr)
		end
	end
	return table.freeze(prs_after_time)
end

local pull_requests = {}

function pull_requests.get_all_after_time(time: number?): { [string]: { PullRequestInfo }? }
	local libs_to_prs_after_time = {}
	local time = time or first_release_time

	for lib, prs in LIBS_TO_PRS do
		local prs_after_time = get_after_time(lib, prs, time)

		if #prs_after_time ~= 0 then
			libs_to_prs_after_time[lib] = prs_after_time
		end
	end
	return table.freeze(libs_to_prs_after_time)
end

function pull_requests.get_after_time(lib: string, time: number?): { PullRequestInfo }
	return (get_after_time(lib, LIBS_TO_PRS[lib], time or first_release_time))
end

do

	for _, lib in fs.readDir("libs") do
		LIBS_TO_PRS[lib] = {}
	end

	for index, pr in PULL_REQUESTS do
		for _, file in pr.files do
			local lib = MATCH(file.path, "^libs/([^/]+)") or MATCH(file.path, "^docs/([^/%.]+)")
	
			if lib then
				local prs = LIBS_TO_PRS[lib]

				if prs then
					table.insert(prs, {
						merged_at = datetime.fromIsoDate(pr.mergedAt).unixTimestamp,
						author = pr.author.login,
						title = pr.title,
						num = pr.number,
					})
				end
			end
		end
	end

end

return table.freeze(pull_requests)