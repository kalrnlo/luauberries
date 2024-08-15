
-- sort libraries
-- script for sorting library entries for docs

local serde = require("@lune/serde")
local fs = require("@lune/fs")

type SidebarItem = { text: string, link: string }

local SIDEBAR_JSON_PATH = "docs/.vitepress/sidebar-libs.json"
local TITLE_PATTERN = "(.-)\n"
local HOME_MD_PATH = "docs/index.md"
local TITLE_KEY = "%- title"

local content = string.gsub(fs.readFile(HOME_MD_PATH), "\r", "")
local section_start, section_end = string.find(content, "features:\n.-\n[^\n ]")

if not (section_end and section_start) then
	error("\27[1;31mNO FEATURES IN HOMEPAGE\27[0m")
end

local section = string.sub(content, section_start, section_end - 1)
local sidebar_libs = {} :: { SidebarItem }
local libs = {} :: { string }
local find_start = 1

local function SUB_KEY_FROM_ENTRY(
	entry_name: string,
	entry: string
): string
	local _, name_end: any = string.find(entry, `{entry_name}: `)
	return string.sub(entry, if name_end then name_end + 1 else 1)
end

while true do
	local _, lib_end, lib = string.find(
		section, "(  %- title:[^\n]+\n[^\n]+\n[^\n]+)", find_start
	)

	if not (lib_end and lib) then
		break
	end

	local title, details, link = string.match(lib, "(.-)\n(.-)\n(.+)")

	if not (title and details and link) then
		continue
	end

	table.insert(sidebar_libs, {
		text = SUB_KEY_FROM_ENTRY(TITLE_KEY, title),
		link = SUB_KEY_FROM_ENTRY("link", link),
	})

	table.insert(libs, lib)
	find_start = lib_end
end

table.sort(libs, function(a, b)
	-- subbing to remove the "- title: " part
	local len_a = #SUB_KEY_FROM_ENTRY(TITLE_KEY, string.match(a, TITLE_PATTERN))
	local len_b = #SUB_KEY_FROM_ENTRY(TITLE_KEY, string.match(b, TITLE_PATTERN))

	return len_a > len_b
end)

local before_section = string.sub(content, 1, section_start - 1)
local sidebar_json = serde.encode("json", sidebar_libs, true)
local after_section = string.sub(content, section_end)

local new_content = `{before_section}features:\
{table.concat(libs, "\n")}\
{after_section}`

fs.writeFile(SIDEBAR_JSON_PATH, sidebar_json)
fs.writeFile(HOME_MD_PATH, new_content)

print(
`\27[1;37mSIDEBAR GENERATED:\27[0m\
{sidebar_json}\
\
\27[1;31mHOME BEFORE:\27[0m\
\27[0;31m{string.sub(content, 5, #content - 4)}\27[0m\
\
\27[1;32mHOME AFTER:\27[0m\
\27[0;32m{string.sub(new_content, 5, #new_content - 4)}\27[0m`
)