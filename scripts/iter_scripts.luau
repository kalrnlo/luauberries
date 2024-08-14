
-- iter scripts
-- recursively iterates over every luau file in a directory
-- and calls a callback that can then optionally overwrite the file

local ends_with = require("ends_with")
local remove = require("remove")
local fs = require("@lune/fs")

local DIRQUEUE = table.create(2)

local function iter_scripts(dir: string, f: (path: string, src: string) -> string?)
	local queue_len = 1
	DIRQUEUE[1] = dir

	while queue_len ~= 0 do
        local current_dir = remove(DIRQUEUE, queue_len)
        queue_len -= 1

        for _, entry in fs.readDir(current_dir) do
            local entry_path = `{current_dir}/{entry}`
            
            if ends_with(entry, ".luau") then
				local new_src = f(entry_path, fs.readFile(entry_path))

				if new_src then
					fs.writeFile(entry_path, new_src)
				end
            elseif fs.isDir(entry_path) then
				queue_len += 1
				DIRQUEUE[queue_len] = entry_path
            end
        end
    end

	table.clear(DIRQUEUE)
end

return iter_scripts
