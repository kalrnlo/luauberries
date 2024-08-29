-- from
-- https://github.com/Corecii/lune-scripts/blob/main/lune/wally-install-lua.luau

--[[
	Wraps `wally install` with type exports in link files.

	Roughly equivalent to wally-package-types, but with support for generics
	with defaults and some support for WaitForChild require paths.
--]]

--[=[ lunar
	about = "Wraps `wally install` with a Lua version of wally-package-types to export types in link files."
]=]

local sort_descending = require("sort_descending")

local genericEqTypes = {
	"^(%b()%s*,)",
	"^(%b{}%s*,)",
	"^(%S+%b<>%s*,)",
	"^(%S+%s*,)",
}

local function parseGenerics(generics: string): { string }
	generics = `{generics},`

	local results = {}

	local cursor = 1
	while true do
		local preTrim = string.match(generics, "^%s*", cursor)
		assert(preTrim)
		cursor += #preTrim

		if #generics - cursor <= 0 then
			break
		end

		local nameWithEq, eq = string.match(generics, "^(%S+)(%s*=%s*)", cursor)
		if nameWithEq and eq then
			table.insert(results, nameWithEq)
			cursor += #nameWithEq
			cursor += #eq

			local matched = false
			for _, genericEq in genericEqTypes do
				local match = string.match(generics, genericEq, cursor)
				if match then
					cursor += #match
					matched = true
					break
				end
			end

			if matched then
				continue
			end
		end

		local name, comma = string.match(generics, "^(%S+)(%s*,)", cursor)
		if name and comma then
			table.insert(results, name)

			cursor += #name
			cursor += #comma

			continue
		end

		error(`Cannot match generics for the following generics:\n\t{generics}\nValue at cursor:\n\t{string.sub(generics, cursor)}`)
	end

	return results
end

local function collect_types(contents: string): { string }
	local result = {}
	for match in string.gmatch(contents, "export%stype%s([^\n]*)") do
		local name, generics = string.match(match, "^(%S+)(%b<>)")
		if name and generics then
			local genericsInner = string.match(generics, "<(.*)>")
			assert(genericsInner)
			local generics = parseGenerics(genericsInner)
			table.insert(result, `{name}<{table.concat(generics, ", ")}>`)
		else
			table.insert(result, string.match(match, "^(%S+)") :: string)
		end
	end
	return result
end

local function create_exports(libname: string, contents: string): string
	local types = collect_types(contents)
	local exports = {}

	for _, type in types do
		table.insert(exports, `export type {type} = {libname}.{type}`)
	end
	sort_descending(exports)
	return table.concat(exports, "\n")
end

return create_exports