
-- iter dir
-- recursively iterates over luau file in a directory
-- and calls a callback that can then optionally change stuff abt the file

local remove = require("./remove")
local fs = require("@lune/fs")

type BaseOptionalFileInfo = {
	file: (string | buffer)?
}

type OptionalPathAndNameInfo = {
	path: nil,
	name: string?,
} | {
	path: string?,
	name: nil,
}

export type OptionalFileInfo = BaseOptionalFileInfo & OptionalPathAndNameInfo

export type FileInfo = {
	path: string,
	name: string,
	file: string,
}

local DIRQUEUE = table.create(2)
local PATH_FORMAT = "%*/%*"

local REMOVE_FILE = fs.removeFile
local WRITE_FILE = fs.writeFile
local READ_FILE = fs.readFile
local FORMAT = string.format
local READ_DIR = fs.readDir
local MATCH = string.match
local IS_FILE = fs.isFile

local function iter_dir(dir: string, f: (info: FileInfo) -> (OptionalFileInfo | "break" | "continue")?)
	local queue_len = 1
	DIRQUEUE[1] = dir

	while queue_len ~= 0 do
        local current_dir = remove(DIRQUEUE, queue_len)
        queue_len -= 1

        for _, entry in READ_DIR(current_dir) do
            local entry_path = FORMAT(PATH_FORMAT, current_dir, entry)
            
			if IS_FILE(entry_path) then
				local name = MATCH(entry, "[^%.]+") or ""
				local file = READ_FILE(entry_path)
				local info = table.freeze({
					path = entry_path,
					file = file,
					name = name,				
				})
				local result = f(info)

				if not result then
					continue
				elseif result == "break" then
					return
				elseif type(result) == "table" then
					local new_path = entry_path

					if result.name then
						REMOVE_FILE(entry_path)
						new_path = FORMAT(PATH_FORMAT, result.name)
					end

					if result.path then
						REMOVE_FILE(entry_path)
						new_path = result.path
					end

					if result.file then
						file = result.file
					end

					WRITE_FILE(new_path, file)
				end
			else
				queue_len += 1
				DIRQUEUE[queue_len] = entry_path
			end
        end
    end

	table.clear(DIRQUEUE)
end

return iter_dir
