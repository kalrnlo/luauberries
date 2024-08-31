local testkit = require("../../testkit")
local url = require("init")

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("url", function()
	do CASE("encode %%20")
		CHECK(url.encode("Je suis allé au cinéma.") == "Je%20suis%20all%C3%A9%20au%20cin%C3%A9ma.")
	end

	do CASE("encode +")
		CHECK(url.encode("Je suis allé au cinéma.", "+") == "Je+suis+all%C3%A9+au+cin%C3%A9ma.")
	end

	do CASE("decode %%20")
		CHECK(url.decode("Je%20suis%20all%C3%A9%20au%20cin%C3%A9ma.") == "Je suis allé au cinéma.")
	end

	do CASE("decode +")
		CHECK(url.decode("Je+suis+all%C3%A9+au+cin%C3%A9ma.", "+") == "Je suis allé au cinéma.")
	end

	do CASE("queryify")
		local query = url.queryify({
			meow = "mrrp",
			mrrp = "meow"
		})
		
		CHECK(query == "?meow=mrrp&mrrp=meow")
	end

	do CASE("read_query")
		local query = "?meow=mrrp&mrrp=meow"
		local tbl = url.read_query(query)

		CHECK(tbl.meow == "mrrp" and tbl.mrrp == "meow")
	end

	do CASE("get_launchdata")
		local launchdata = "https://libs.luau.lol/lmao&meow=mrrp&mrrp=meow&launchdata=kitty catters unite now!"
		local mock_player = table.freeze({
			GetJoinData = function()
				return table.freeze({
					LaunchData = launchdata
				})
			end
		})

		CHECK(url.get_launchdata(mock_player :: any) == "kitty catters unite now!")
	end
end)