
-- make lib releases
-- makes new releases for each lib thats changed

local DateTime = require("@lune/DateTime")
local diff_reader = require("diff_reader")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local depgraph = require("depgraph")
local summon = require("summon")
local fs = require("@lune/fs")
local zip = require("zip")

local RELEASES = summon("gh", { "release", "list", "--limit", "1000" })
local LIBS_CHANGED = diff_reader.libs()
local GMATCH = string.gmatch

local function LIB_LATEST_RELEASE_DATE(lib: string): number
    local pattern = `{lib} v%d+%.%d+%.%d+\t([^\t]+)\t{lib}%-v%d+%.%d+%.%d+\t(%S+)`
    local latest_date = 0

    for type, iso in GMATCH(RELEASES, pattern) do
        print(type, iso)
        if type ~= "Draft" then
            local date = DateTime.fromIsoDate(iso).unixTimestamp

            if latest_date < date then
                latest_date = date
            end
        end
    end
    return latest_date
end

local function get_release_notes_for_lib(lib: string, release_prefix: string)
    -- Get all release tags that match the prefix
    --local releases = list_releases()



    -- Get releases that match the prefix and include the file name in the title
    local releases_json = summon("gh",{
        "release", "list",
        "--limit", "1000",
		"--json", "tagName", "name"
       	--"--jq", string.format(
            --`[.[] | select(.TAGNAME | startswith("{release_prefix}")) | select(.name | contains("{file_name}")) | .tagName]`,
            --release_prefix, file_name
        --)
    })


print(releases_json)
--[[
    -- Filter commits not in releases
    local filtered_commits = {}
    for commit in all_commits:gmatch("[^\n]+") do
        local in_release = false
        for release in releases:gmatch("[^\n]+") do
            if release:match("^" .. release_prefix) then
                local release_commit = summon("gh", {"rev-parse", release})
				warn(release_commit)
				local res =  summon("git", {"merge-base", "--is-ancestor", commit, release_commit})
				warn(res)

                if res ~= "" then
                    in_release = true
                    break
                end
            end
        end
        if not in_release then
            table.insert(filtered_commits, commit)
        end
    end

    -- Get commit messages for filtered commits
    local commit_notes = {}
    for _, commit in ipairs(filtered_commits) do
        local message = summon("gh", {"log", "--format=%s", "-n", "1", commit})
        table.insert(commit_notes, message)
    end

    return commit_notes
	--]]
end

local function parseGitLog(logOutput)
    local commits = {}
    local currentCommit = {}
    local inBody = false

    for line in logOutput:gmatch("[^\n]+") do
        if line:match("^commit %x+") then
            if next(currentCommit) ~= nil then
                table.insert(commits, currentCommit)
            end
            currentCommit = {
                hash = line:match("commit (%x+)"),
                body = ""
            }
            inBody = false
        elseif line:match("^Author: ") then
            currentCommit.author = line:match("Author: (.+)")
        elseif line:match("^Date: ") then
            currentCommit.date = line:match("Date:%s+(.+)")
        elseif line:match("^%s+") and not inBody then
            currentCommit.subject = line:match("^%s+(.+)")
            inBody = true
        elseif inBody and line ~= "" then
            currentCommit.body = currentCommit.body .. line:match("^%s*(.-)%s*$") .. "\n"
        end
    end

    if next(currentCommit) ~= nil then
        table.insert(commits, currentCommit)
    end

    -- Trim trailing newline from body
    for _, commit in ipairs(commits) do
        commit.body = commit.body:gsub("\n$", "")
    end

    return commits
end

-- Example usage:
local exampleLog = [[
commit d46612a46f27b637d63a960ae95dfa8ecdfc5606
Author: kalrnlo <azgoodlo95@gmail.com>
Date:   Sat Aug 10 12:35:32 2024 -0400

    Update diff to table to ignore changes from certain files

commit 558a524099e3e69b79f8ecddaec99f335fc14e47
Author: kalrnlo <azgoodlo95@gmail.com>
Date:   Thu Aug 8 18:03:36 2024 -0400

    Switch to new library format

    * Each library now has their own LIBINFO.json, this is for adding tags (keywords) and specifying the version for each library (note: none of the LIBINFO.json's are actually filled out, its all just placeholders rn)
    * test files are now just test.luau, not LIBNAME.test.luau
    * created init folders for libraries with more than one module

commit 5404a8da1403d42ed9966707f6d9a6b168dcc46d
Author: kalrnlo <azgoodlo95@gmail.com>
Date:   Sun Aug 4 16:54:25 2024 -0400

    Rename library main files to init.luau (because it makes generating releases easier)
]]

local parsedCommits = parseGitLog(exampleLog)

local repoUrl = "https://github.com/kalrnlo/rbxlibs/commit/"
for _, commit in ipairs(parsedCommits) do
    commit.url = `{repoUrl}{commit.hash}`
end

-- Print parsed commits
print(parsedCommits)
process.exit()