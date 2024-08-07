
-- base gem
-- class that the other gems inherit from as both classes share 
-- the exact same methods for dealing w datastore versioning

-- NOTE: do when DataStore:GetVersionAtTimeAsync() is added
-- https://devforum.roblox.com/t/upcoming-changes-to-data-stores-versioning/3042258

local t = require("../types")

local basegem_proto = {} :: t.BaseGemPrototype
(basegem_proto :: any).__index = basegem_proto 

basegem_proto.revert = function(gem: t.BaseGem, time: number, auto_migrate: boolean?): (boolean, string?)
	local gem: t.GlobalGem | t.Gem = gem :: any
	local chest = gem.chest

	error("[CHEST] method not implemented, waiting for DataStore:GetVersionAtTimeAsync() to be added")
end :: any

basegem_proto.datastore_version = function(gem: t.BaseGem, time: number): (boolean, string?)
	local gem: t.GlobalGem | t.Gem = gem :: any
	local chest = gem.chest

	error("[CHEST] method not implemented, waiting for DataStore:GetVersionAtTimeAsync() to be added")
end :: any

return table.freeze(basegem_proto)