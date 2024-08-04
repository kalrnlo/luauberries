
local fs = require("@lune/fs")

local FFC_FORMAT = `:FindFirstChild("%s")`
local WFC_FORMAT = `:WaitForChild("%s")`
local DOT_FORMAT = ".%s"

type RequireType = "RobloxDots" | "RobloxWaitForChild" | "RobloxFindFirstChild"

local function GET_FORMAT_FOR_TYPE(type: RequireType?): string
	return if type == "RobloxFindFirstChild" then
			FFC_FORMAT
		elseif type == "RobloxWaitForChild" then
			WFC_FORMAT
		else
			DOT_FORMAT
end

type ConvertInfo = {
	folder_module_name: string?,

}

local function convert(path: string, to: RequireType?): string
	if fs.isDir(path) then
		path = `{path}/init`
	end

	local script_parent_start = string.sub(path, 1, 3)
	local script_start = string.sub(path, 1, 2)

	local path = (
		string.gsub(
			string.gsub(
				string.gsub(
						string.gsub(path, "%.%.", ""),
						"%./", ""
				),
				"%.luau", ""
			),
			"%.lua", ""
		)
	)
	local split = string.split(path, "/")
	local concat = table.create(#split)
	local format = GET_FORMAT_FOR_TYPE(to)

	for index, name in split do
		concat[index] = string.format(format, name)
	end

	local result = table.concat(concat)
	local is_dots = format == DOT_FORMAT

	if is_dots then 
		result = string.sub(result, 2)
	end

	if script_start == "%./" then
		result = if is_dots then `script.{result}` else `script{result}`
	elseif script_parent_start == "%.%./" then
		result = if is_dots then `script.Parent.{result}` else `script.Parent{result}`
	else
		result = if is_dots then `script.{result}` else `script{result}`
	end

	return result
end

return convert