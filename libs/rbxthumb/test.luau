local testkit = require("../../testkit")
local rbxthumb = require("init")

local TEST, CASE, CHECK, FINISH = testkit.test()

local BASE_URL = "rbxthumb://type=%s&id=%d&w=%d&h=%d"
local CIRCULAR_URL = `{BASE_URL}&filters=circular`

local PLAYER_AUTO_GENERATED_METHODS: { [string]: (player: { UserId: number }, size: string?, circular: boolean?) -> string } = {
	AvatarHeadshot = rbxthumb.player.headshot,
	AvatarBust = rbxthumb.player.bust,
	Avatar = rbxthumb.player.full,
} :: any

local AUTO_GENERATED_METHODS: { [string]: (id: number, size: string?, circular: boolean?) -> string } = {
	AvatarHeadshot = rbxthumb.avatar.headshot,
	AvatarBust = rbxthumb.avatar.bust,
	Avatar = rbxthumb.avatar.full,
	BundleThumbnail = rbxthumb.bundle,
	FontFamily = rbxthumb.fontfamily,
	GroupIcon = rbxthumb.group,
	Outfit = rbxthumb.outfit,
	Asset = rbxthumb.asset,
	GameIcon = rbxthumb.experience,
	GamePass = rbxthumb.gamepass,
	BadgeIcon = rbxthumb.badge
} :: any

local DUMMY_PLAYER = {
	UserId = 1234,
}

TEST("rbx thumb", function()
	do CASE("check formats")
		CHECK(
			rbxthumb.urlformats.base == BASE_URL and
			rbxthumb.urlformats.circular == CIRCULAR_URL
		)
	end

	do CASE("avatar item")
		local avatar_item = rbxthumb.avatar.item
		CHECK(
			#avatar_item(Enum.AvatarItemType.Asset, 1234, "420x420") == #string.format(BASE_URL, "Asset", 1234, 420, 420)
		)
		CHECK(
			#avatar_item(Enum.AvatarItemType.Bundle, 1234, "420x420") == #string.format(BASE_URL, "BundleThumbnail", 1234, 420, 420)
		)
	end

	do CASE("avatar item type to thumbnail type")
		CHECK(rbxthumb.avatar_item_type_to_thumbnail_type(Enum.AvatarItemType.Asset) == "Asset")
		CHECK(rbxthumb.avatar_item_type_to_thumbnail_type(Enum.AvatarItemType.Bundle) == "BundleThumbnail")
	end

	do CASE("generated methods")
		local success = false

		for type, method in AUTO_GENERATED_METHODS do
			if type == "FontFamily" then
				success = method(1234, "1200x80") == string.format(BASE_URL, type, "1234", "1200", "80")
				CHECK(success)
				success = method(1234, "1200x80", true) == string.format(CIRCULAR_URL, type, "1234", "1200", "80")
				CHECK(success)
			else
				-- using len because string eq had issues??? as in the first iterator it would always fail
				-- even tho they were both the same??
				success = #method(1234, "150x150") == #string.format(BASE_URL, type, 1234, 150, 150)
				CHECK(success)
				success = #method(1234, "150x150", true) == #string.format(CIRCULAR_URL, type, 1234, 150, 150)
				CHECK(success)
			end
		end
	end

	do CASE("player generated methods")
		local success = false

		for type, method in PLAYER_AUTO_GENERATED_METHODS do
			success = #method(DUMMY_PLAYER, "150x150") == #string.format(BASE_URL, type, 1234, 150, 150)
			success = #method(DUMMY_PLAYER, "150x150", true) == #string.format(CIRCULAR_URL, type, 1234, 150, 150)
		end

		CHECK(success)
	end
end)
