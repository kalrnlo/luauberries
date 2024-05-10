--!strict

-- GetModelOrPartSize
-- A simple module for getting either a model or parts size
-- @Kalrnlo
-- 10/05/2024

local metaize = require(script.Parent.metaize)

local function GET_PV_INSTANCE_SIZE(self: unknown, pv_instance: PVInstance | BasePart | Model | Actor | Tool): Vector3
	if pv_instance:IsA("BasePart") then
		return pv_instance.Size
	elseif pv_instance:IsA("Model") then
		local _, size = pv_instance:GetBoundingBox()
		return size
	else
		return Vector3.zero
	end
end

local function GET_PV_INSTANCE_EXTENTS_SIZE(pv_instance: PVInstance | BasePart | Model | Actor | Tool): Vector3
	if pv_instance:IsA("BasePart") then
		return pv_instance.ExtentsSize
	elseif pv_instance:IsA("Model") then
		return pv_instance:GetExtentsSize()
	else
		return Vector3.zero
	end
end

local tbl = table.freeze {
	extents = GET_PV_INSTANCE_EXTENTS_SIZE,
}
local mt = metaize {
	__call = GET_PV_INSTANCE_SIZE,
}

local export = setmetatable(tbl, mt) :: typeof(setmetatable(tbl, mt))

return export