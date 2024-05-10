--!strict

-- asset type to accessory type
-- utility function for converting an asset type to an accessory type
-- @kalrnlo
-- 10/05/2024

local UNKNOWN_ENUM = Enum.AccessoryType.Unknown

local function ASSET_TYPE_TO_ACCESSORY_TYPE(asset_type: Enum.AssetType): Enum.AccessoryType
    local success, enum_item = pcall(function(EnumItemName)
         return Enum.AccessoryType[EnumItemName]
    end, string.split(asset_type.Name, "Acc")[1])

    return if success then enum_item else UNKNOWN_ENUM
end

return ASSET_TYPE_TO_ACCESSORY_TYPE