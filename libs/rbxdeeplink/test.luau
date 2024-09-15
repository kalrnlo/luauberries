local testkit = require("../../testkit")
local rbxdeeplink = require("init")
local url = require("../url")

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("rbxdeeplink", function()
	
	do CASE("get_launchdata")
		local launchdata = "https://libs.luau.lol/lmao&meow=mrrp&mrrp=meow&launchdata=kitty catters unite now!"
		local mock_player = table.freeze({
			GetJoinData = function()
				return table.freeze({
					LaunchData = launchdata
				})
			end
		})

		CHECK(rbxdeeplink.get_launchdata(mock_player :: any) == "kitty catters unite now!")
	end

	do CASE("format")
		CHECK(rbxdeeplink.format(0, "meow") == "https://www.roblox.com/games/start?placeId=0&launchData=meow")
	end

	do CASE("format appsflyer")
		local regular = url.encode("https://www.roblox.com/games/start?placeId=0&launchData=meow")
		CHECK(rbxdeeplink.format_appsflyer(0, "meow") == `https://ro.blox.com/Ebh5?af_dp={regular}&af_web_dp={regular}`)
	end

end)