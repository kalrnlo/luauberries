--!strict

-- rbxthumbutil
-- module for easily creating roblox thumbnail urls
-- @kalrnlo
-- 26/04/2024

local BASE_URL = "rbxthumb://type=%s&id=%d&w=%s&h=%s"
local CIRCULAR_URL = `{BASE_URL}&filters=circular`

export type ThumbnailType = "Asset" | "Avatar" | "AvatarHeadShot" | "BadgeIcon"  | 
	"BundleThumbnail" | "GameIcon" | "GamePass" | "GroupIcon" | "Outfit" | "FontFamily" | 
	"AvatarBust"

export type ThumbnailSize = "1200×80" | "720x720" | "420x420" |"352x352" | "150x150" | 
	"100x100" | "60x60" | "50x50" | "48x48" | "180x180"

type HeadshotThumbnailSize = "48×48" | "60×60" | "100×100" | "150×150" | "180×180" |
    "352×352" | "420×420"

type BustThumbnailSize = "100x100" | "150x15" | "75×75" | "100×100" | "150×150" | "180×180" | 
    "352×352" | "420×420"

type FullThumbnailSize = "50×50" | "60×60" | "75×75" | "100×100" | "150×150" | "180×180" | 
    "352×352" | "420×420"

local function FORMAT_RBXTHUMB_URL(id: number, type: ThumbnailType, size: ThumbnailSize, circular: boolean?)
	return string.format(
		if circular then CIRCULAR_URL else BASE_URL,
		type,
		id,
		table.unpack(string.split(size, "x"))
	)
end

local function avatar_item_type_to_thumbnail_type(avatar_item_type: Enum.AvatarItemType): "Asset" | "BundleThumbnail"
	if AvatarItemType == Enum.AvatarItemType.Bundle then
		return "BundleThumbnail"
	elseif AvatarItemType == Enum.AvatarItemType.Asset then
		return "Asset"
	else
		error "[RBX_THUMB_UTIL]: Invalid avatar_item_type provided"
	end
end

local exports = table.freeze {
    format = FORMAT_RBXTHUMB_URL,
    avatar = table.freeze {
        headshot,
        bust,
        full,
    },
    avatar = table.freeze {
        headshot,
        bust,
        full,
    },
    experience,
    fontfamily,
    badge,
    gamepass,
    group,
    bundle,
    outfit,
    asset,

    avatar_item_type_to_thumbnail_type,
}

--!strict

-- RbxThumbUtils
-- Wraps the rbxthumb URL api surface to generate a URL for a thumbnail on the cloud.
-- These thumbnails are automatically batched for performance.
-- Originally by @Quenty
-- Modified by @Kalrnlo
-- 16/01/2023

export type RobloxThumbnailType = "Asset" | "Avatar" | "AvatarHeadShot" | "BadgeIcon"  | 
	"BundleThumbnail" | "GameIcon" | "GamePass" | "GroupIcon" | "Outfit" | "FontFamily" | 
	"AvatarBust"
export type RobloxThumbnailSize = "1200×80" | "720x720" | "420x420" |"352x352" | "150x150" | 
	"100x100" | "60x60" | "50x50" | "48x48" | "180x180"

local UrlBase = "rbxthumb://type=%s&id=%d&w=%d&h=%d"
local CircularUrlBase = `{UrlBase}&filters=circular`
local RbxThumbUtils = {}

function RbxThumbUtils.AvatarItemTypeToThumbnailType(AvatarItemType: Enum.AvatarItemType): "Asset" | "BundleThumbnail"
	if AvatarItemType == Enum.AvatarItemType.Bundle then
		return "BundleThumbnail"
	elseif AvatarItemType == Enum.AvatarItemType.Asset then
		return "Asset"
	else
		return nil :: any
	end
end

function RbxThumbUtils.GetThumbnail(
	ThumbnailType: RobloxThumbnailType,
	Id: number,
	ThumbnailSize: RobloxThumbnailSize?,
	IsCircular: boolean?
)
	local ThumbnailSize = ThumbnailSize or "150x150"	
	local IsCircular = IsCircular or false
	local Height: number
	local Width: number

	for Match in ThumbnailSize:gmatch("%d+") do
		-- The first number in the thumbnailsize string is always
		-- the width, with the second being the height
		-- so were just using a loop to easily extract those
		if not Width then
			Width = tonumber(Match) :: number
			continue
		else
			Height = tonumber(Match) :: number
			break
		end
	end

	if IsCircular then
		return string.format(CircularUrlBase, ThumbnailType, Id, Width, Height)
	else
		return string.format(UrlBase, ThumbnailType, Id, Width, Height)	
	end
end

function RbxThumbUtils.GetExperienceIconThumbnail(
	ExperienceId: number,
	ThumbnailSize: "150x150"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("GameIcon", ExperienceId, ThumbnailSize, IsCircular)
end

function RbxThumbUtils.GetAvatarHeadShotThumbnail(
	UserId: number,
	ThumbnailSize: "48×48" | "60×60" | "100×100" | "150×150" | "180×180" |
	"352×352" | "420×420"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("AvatarHeadShot", UserId, ThumbnailSize :: any, IsCircular)
end

function RbxThumbUtils.GetPlayerHeadShotThumbnail(
	Player: Player,
	ThumbnailSize: "48×48" | "60×60" | "100×100" | "150×150" | "180×180" | 
	"352×352" | "420×420",
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("AvatarHeadShot", Player.UserId, ThumbnailSize :: any, IsCircular)
end

function RbxThumbUtils.GetPlayerBustThumbnail(
	Player: Player,
	ThumbnailSize: "100x100" | "150x15" | "75×75" | "100×100" | "150×150" | "180×180" | 
	"352×352" | "420×420",
	IsCircular: boolean?
)	
	return RbxThumbUtils.GetThumbnail("AvatarBust", Player.UserId, ThumbnailSize :: any, IsCircular)
end

function RbxThumbUtils.GetPlayerFullThumbnail(
	Player: Player,
	ThumbnailSize: "50×50" | "60×60" | "75×75" | "100×100" | "150×150" | "180×180" | 
	"352×352" | "420×420"?, 
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("Avatar", Player.UserId, ThumbnailSize :: any, IsCircular)
end

function RbxThumbUtils.GetAvatarBustThumbnail(
	UserId: number,
	ThumbnailSize: "50×50" | "60×60" | "75×75" | "100×100" | "150×150" |
	"180×180" | "352×352" | "420×420",
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("AvatarBust", UserId, ThumbnailSize :: any, IsCircular)
end

function RbxThumbUtils.GetFullAvatarThumbnail(
	UserId: number,
	ThumbnailSize: "48×48" | "60×60" | "100×100" | "150×150" | "180×180" |
	"352×352" | "420×420" | "720×720"?, 
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("Avatar", UserId, ThumbnailSize :: any, IsCircular)
end

function RbxThumbUtils.GetFontFamilyThumbnail(
	AssetId: number,
	ThumbnailSize: "1200×80"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("FontFamily", AssetId, ThumbnailSize or "1200×80", IsCircular)
end


function RbxThumbUtils.GetBadgeIconThumbnail(
	BadgeId: number,
	ThumbnailSize: "150x150"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("BadgeIcon", BadgeId, ThumbnailSize, IsCircular)
end

function RbxThumbUtils.GetGroupIconThumbnail(
	GroupId: number,
	ThumbnailSize: "150x150" | "420x420"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("GroupIcon", GroupId, ThumbnailSize, IsCircular)
end

function RbxThumbUtils.GetGamePassThumbnail(
	GamepassId: number,
	ThumbnailSize: "150x150"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("GamePass", GamepassId, ThumbnailSize, IsCircular)
end

function RbxThumbUtils.GetBundleThumbnail(
	BundleId: number,
	ThumbnailSize: "150x150" | "420x420"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("BundleThumbnail", BundleId, ThumbnailSize, IsCircular)
end

function RbxThumbUtils.GetOutfitThumbnail(
	OutfitId: number,
	ThumbnailSize: "150x150" | "420x420"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("Outfit", OutfitId, ThumbnailSize, IsCircular)
end

function RbxThumbUtils.GetAssetThumbnail(
	AssetId: number,
	ThumbnailSize: "150x150" | "420x420"?,
	IsCircular: boolean?
)
	return RbxThumbUtils.GetThumbnail("Asset", AssetId, ThumbnailSize, IsCircular)
end

return RbxThumbUtils

