--!strict

-- GetModelOrPartSize
-- A simple function for getting either a model or parts size
-- @Kalrnlo
-- 07/05/2024

local function get_model_or_part_size(pv_instance: PVInstance, use_extents: boolean?): Vector3
	if pv_instance:IsA("BasePart") then
		if use_extents then
			return pv_instance.ExtentsSize
		else
			return pv_instance.Size
		end
	elseif pv_instance:IsA("Model") then
		if use_extents then
			return pv_instance:GetExtentsSize()
		else
			local _, Size = pv_instance:GetBoundingBox()
			return Size
		end
	else
		return Vector3.zero
	end
end

return get_model_or_part_size