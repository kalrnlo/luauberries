--!optimize 2
--!native

-- dep graph
-- module for generating a dependency graph for all libraries

local remove_from_end = require("remove_from_end")
local process = require("@lune/process")
local ends_with = require("ends_with")
local fs = require("@lune/fs")

export type DependencyInfo = {	
	shallow: { string },
	has_deps: boolean,
	deep: { string },
}

local REQUIRE_PATTERN = "local%s+%w+%s*=%s*require%s*%(%-?%-?%-?[\"'`](.-)[\"'`]%)"
local GRAPH = {} :: { [string]: DependencyInfo }
local LINE_PATTERN = "[^\r\n]+"
local GMATCH = string.gmatch
local MATCH = string.match
local SUB = string.sub

local function REMOVE_OR_ERROR<V>(t: { V }, index: number?): V
	local value = table.remove(t, index)

	if not value then
		error("this is supposed to be unreachable")
	end
	return value
end

local function find_lib_in_relative_path(path: string): string?
	local found_lib = MATCH(remove_from_end(path, "/init"), "([^/]+)$")

	return if found_lib and GRAPH[found_lib] then
			found_lib
		else
			nil
end

for _, lib in fs.readDir("libs") do
	GRAPH[lib] = {
		has_deps = false,
		shallow = {},
		deep = {},
	}
end

for lib, depinfo in GRAPH do
	local dirqueue = { `libs/{lib}` }
	local shallow = depinfo.shallow
    
    while #dirqueue ~= 0 do
        local current_dir = REMOVE_OR_ERROR(dirqueue, 1)
        
        for _, entry in fs.readDir(current_dir) do
            local entry_path = `{current_dir}/{entry}`
            
            if ends_with(entry, ".luau") then
                local contents = fs.readFile(entry_path)

                for require_path in GMATCH(contents, REQUIRE_PATTERN) do
                    local deplib = find_lib_in_relative_path(require_path)
                    
                    if deplib and not table.find(shallow, deplib) then
                        table.insert(shallow, deplib)
                    end
                end
            elseif fs.isDir(entry_path) then
                table.insert(dirqueue, entry_path)
            end
        end
    end
end

for lib, depinfo in GRAPH do
	local shallow = depinfo.shallow
	local depqueue = table.clone(depinfo.shallow)
	local deep = depinfo.deep
	local found = {}
    
    while #depqueue ~= 0 do
        local current = REMOVE_OR_ERROR(depqueue, 1)
        
        if not found[current] then
			table.insert(deep, current)
            found[current] = true
            
            -- Add the shallow dependencies of the current item to the queue
            for _, dep in GRAPH[current].shallow do
                table.insert(depqueue, dep)
            end
        end
    end

	if #deep == #shallow then
		depinfo.deep = table.freeze(shallow)
	else
		table.freeze(shallow)
		table.freeze(deep)
	end
end

for _, depinfo in GRAPH do
	if #depinfo.shallow ~= 0 then
		depinfo.has_deps = true
	end
	table.freeze(depinfo)
end

if process.args[1] == "print" then
	print(GRAPH)
end

return table.freeze(GRAPH)