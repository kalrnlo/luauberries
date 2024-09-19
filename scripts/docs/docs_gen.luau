
-- docs gen
-- generates sidebar, and homepage

local remove_from_end = require("../remove_from_end")
local process = require("@lune/process")
local iter_dir = require("../iter_dir")
local serde = require("@lune/serde")
local fs = require("@lune/fs")

type SidebarItem = { text: string, link: string }

type LibdocInfo = {
	items: { LibdocInfo }?,
	link: string,
	text: string,
}

local IGNORE = table.freeze({ ".vitepress", "public", "index.md", "installing.md" })
local FEATURE_FORMAT = "  - title: %*\n    details: %*\n    link: %*\n"
local HOME_SRC = fs.readFile("docs/index.md")
local DOCDESCS = {} :: { [string]: string }
local FANCY_URL_PATTERN = "%[(.-)%]%(.-%)"
local LIBDOCS = {} :: { LibdocInfo }
local DESC_PATTERN = "\n\n(.-)\n\n"

local FORMAT = string.format
local UPPER = string.upper
local MATCH = string.match
local GSUB = string.gsub
local SUB = string.sub

local function NAME_FROM_FILE_NAME(file_name: string): string
	local without_file_ext = remove_from_end(file_name, ".md")
	local upper_first_char = GSUB(without_file_ext, "^%a", UPPER)

	return (GSUB(upper_first_char, "%-%a", function(dash_and_char)
		return ` {UPPER(SUB(dash_and_char, 2, 2))}`
	end))
end

local function GET_SHORTENED_DESC(file: string): string
	local desc = MATCH(GSUB(file, "\r", ""), DESC_PATTERN)

	if desc then
		return GSUB(desc, FANCY_URL_PATTERN, function(url_name)
			return GSUB(url_name, "`", "")
		end)
	else
		return "n/a"
	end
end

for _, lib_doc in fs.readDir("docs") do
	if table.find(IGNORE, lib_doc) then
		continue
	end
	local name = NAME_FROM_FILE_NAME(lib_doc)
	local path = `docs/{lib_doc}`

	if fs.isFile(path) then
		DOCDESCS[name] = GET_SHORTENED_DESC(fs.readFile(path))
		table.insert(LIBDOCS, table.freeze({
			link = `/{lib_doc}`,
			text = name,
		}))
	else
		local index_path = `{path}/index.md`
		local index = fs.isFile(index_path)

		if index then
			local relative_index_path = `/{lib_doc}/index.md`
			DOCDESCS[name] = GET_SHORTENED_DESC(fs.readFile(index_path))
			local items = {} :: { LibdocInfo }
			local libdoc_info = {
				link = relative_index_path,
				items = items,
				text = name,
			}

			iter_dir(path, function(file_info)
				local file_path = file_info.path
				
				if file_path ~= index_path then
					table.insert(items, {
						text = NAME_FROM_FILE_NAME(file_info.name),
						link = MATCH(file_info.path, "docs(.+)") or "",
					})
				end
				return
			end)

			table.insert(LIBDOCS, libdoc_info)
		else
			error("[DOCS GEN] cannot have docs sub dir without an index.md file")
		end
	end
end

table.sort(LIBDOCS, function(a, b)
	return #a.text > #b.text
end)

local before_features = MATCH(HOME_SRC, "((.+)features:)")
local features = table.create(#LIBDOCS)

for index, libdoc in LIBDOCS do
	local name = libdoc.text
	features[index] = FORMAT(
		FEATURE_FORMAT, name, DOCDESCS[name], libdoc.link
	)
end

fs.writeFile("docs/.vitepress/sidebar-libs.json", serde.encode("json", LIBDOCS))
fs.writeFile("docs/index.md", `{before_features}\n{table.concat(features)}---`)
process.exit()
