--!strict

-- Metaize
-- utility function for making classes
-- @kalrnlo
-- 23/04/2024

local function metaize(metatable: {[string]: any}, inherit: {[string]: any}?)
    if inherit then
        setmetatable(metatable, inherit)
    end
    metatable.__index = metatable
    return table.freeze(metatable)
end

return metaize :: (<mt>(mt: mt) -> mt & { __index: mt }) 
    & (<MT, MTK, MTV, P, PK, PV>(mt: MT & {[MTK]: MTV}, inherit: P & {[PK]: PV}) -> MT & { __index: MT } & P)