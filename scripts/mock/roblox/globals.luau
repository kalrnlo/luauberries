--!nocheck
--!nolint

-- globals
-- sets roblox globals that dont exist in lune

local roblox = require("@lune/roblox")
local datetime = require("datetime")

do
	NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint
	PhysicalProperties = roblox.PhysicalProperties	
	NumberSequence = roblox.NumberSequence
	ColorSequence = roblox.ColorSequence
	Region3int16 = roblox.Region3int16
	Vector2int16 = roblox.Vector2int16
	Vector3int16 = roblox.Vector3int16
	NumberRange = roblox.NumberRange
	BrickColor = roblox.BrickColor
	task = require("@lune/task")
	Instance = roblox.Instance
	Region3 = roblox.Region3
	Vector3 = roblox.Vector3
	Vector2 = roblox.Vector2
	CFrame = roblox.CFrame
	Color3 = roblox.Color3
	Faces = roblox.Faces
	UDim2 = roblox.UDim2
	DateTime = datetime
	Font = roblox.Font
	Rect = roblox.Rect
	UDim = roblox.UDim
	Enum = roblox.Enum
	Ray = roblox.Ray

	--game = Instance.new("DataModel")

	for key, value in roblox do
		if type(value) == "table" and type(value.new) == "function" then
			_G[key] = value
		end
	end
	_G["DateTime"] = datetime
	_G["Enum"] = Enum
end

return nil
