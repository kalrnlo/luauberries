--!strict

-- rbxthumb
-- module for easily creating roblox thumbnail urls, based on nevermores rbxthumbutil
-- although with types 
-- @kalrnlo
-- 29/04/2024

type PlayerThumbnailFormatter<sizes> = (player: Player, size: sizes, circular: boolean?) -> string
type ThumbnailFormatter<sizes> = (id: number, size: sizes, circular: boolean?) -> string

export type ThumbnailType = "Asset" | "Avatar" | "AvatarHeadShot" | "BadgeIcon"  | 
	"BundleThumbnail" | "GameIcon" | "GamePass" | "GroupIcon" | "Outfit" | "FontFamily" | 
	"AvatarBust"

export type ThumbnailSize = "1200×80" | "720x720" | "420x420" |"352x352" | "150x150" | 
	"100x100" | "60x60" | "50x50" | "48x48" | "180x180"

type AvatarHeadshotThumbnailSize = "48×48" | "60×60" | "100×100" | "150×150" | "180×180" |
    "352×352" | "420×420"

type AvatarBustThumbnailSize = "100x100" | "150x15" | "75×75" | "100×100" | "150×150" | "180×180" | 
    "352×352" | "420×420"

type FullAvatarThumbnailSize = "50×50" | "60×60" | "75×75" | "100×100" | "150×150" | "180×180" | 
    "352×352" | "420×420"

local BASE_URL = "rbxthumb://type=%*&id=%*&w=%*&h=%*"
local CIRCULAR_URL = `{BASE_URL}&filters=circular`
local ASSET_ENUM = Enum.AvatarItemType.Asset
local BUNDLE_STR = "BundleThumbnail"
local DEFUALT_SIZE_NUM = 150
local ASSET_STR = "Asset"
local X = "x"

local function avatar_item_type_to_thumbnail_type(avatar_item_type: Enum.AvatarItemType): "Asset" | "BundleThumbnail"
    return if avatar_item_type == ASSET_ENUM then ASSET_STR :: any else BUNDLE_STR
end

local function SPLIT_SIZE(size: ThumbnailSize?, defualt_width: number, defualt_height: number): (number, number)
    if size then
        local splitted = string.split(size, X)
        return tonumber(splitted[1]) or defualt_width, tonumber(splitted[2]) or defualt_height
    else
        return defualt_width, defualt_height
    end
end

local function RAW_FORMAT(id: number, type: ThumbnailType, width: number, height: number, circular: boolean?)
	return string.format(
		if circular then CIRCULAR_URL else BASE_URL,
		type,
		id,
        width,
        height
	)
end

local function FORMAT_RBXTHUMB_URL(id: number, type: ThumbnailType, size: ThumbnailSize, circular: boolean?)
    local width, height = SPLIT_SIZE(size, DEFUALT_SIZE_NUM, DEFUALT_SIZE_NUM)
    return RAW_FORMAT(id, type, width, height, circular)
end

local function CREATE_PLAYER_FORMATTER<sizes>(type: ThumbnailType, defualt_width: number?, defualt_height: number?): PlayerThumbnailFormatter<sizes>
    local defualt_height = defualt_height or DEFUALT_SIZE_NUM
    local defualt_width = defualt_width or DEFUALT_SIZE_NUM

    return function(player: Player, size: sizes?, circular: boolean?)
        return RAW_FORMAT(player.UserId, type, SPLIT_SIZE(size, defualt_width, defualt_height), circular)
    end
end

local function CREATE_FORMATTER<sizes>(type: ThumbnailType, defualt_width: number?, defualt_height: number?): ThumbnailFormatter<sizes>
    local defualt_height = defualt_height or DEFUALT_SIZE_NUM
    local defualt_width = defualt_width or DEFUALT_SIZE_NUM

    return function(id: number, size: sizes?, circular: boolean?)
        local width, height = SPLIT_SIZE(size :: any, defualt_width, defualt_height)
        return RAW_FORMAT(id, type, width, height, circular)
    end
end

local exports = table.freeze {
    avatar = table.freeze {
        headshot = CREATE_FORMATTER("AvatarHeadShot") :: ThumbnailFormatter<AvatarHeadshotThumbnailSize>,
        bust = CREATE_FORMATTER("AvatarBust") :: ThumbnailFormatter<AvatarBustThumbnailSize>,
        full = CREATE_FORMATTER("Avatar") :: ThumbnailFormatter<FullAvatarThumbnailSize>,
    },
    player = table.freeze {
        headshot = CREATE_PLAYER_FORMATTER("AvatarHeadShot") :: PlayerThumbnailFormatter<AvatarHeadshotThumbnailSize>,
        bust = CREATE_PLAYER_FORMATTER("AvatarBust") :: PlayerThumbnailFormatter<AvatarBustThumbnailSize>,
        full = CREATE_PLAYER_FORMATTER("Avatar") :: PlayerThumbnailFormatter<FullAvatarThumbnailSize>,
    },
    bundle = CREATE_FORMATTER("BundleThumbnail") :: ThumbnailFormatter<"150x150" | "420x420">,
    fontfamily = CREATE_FORMATTER("FontFamily", 1200, 80) :: ThumbnailFormatter<"1200×80">,
    group = CREATE_FORMATTER("GroupIcon") :: ThumbnailFormatter<"150x150" | "420x420">,
    outfit = CREATE_FORMATTER("Outfit") :: ThumbnailFormatter<"150x150" | "420x420">,
    asset = CREATE_FORMATTER("Asset") :: ThumbnailFormatter<"150x150" | "420x420">,
    experience = CREATE_FORMATTER("GameIcon"):: ThumbnailFormatter<"150x150">,
    gamepass = CREATE_FORMATTER("GamePass") :: ThumbnailFormatter<"150x150">,
    badge = CREATE_FORMATTER("BadgeIcon") :: ThumbnailFormatter<"150x150">,

    avatar_item_type_to_thumbnail_type = avatar_item_type_to_thumbnail_type,
    format = FORMAT_RBXTHUMB_URL,
}

return exports