local testkit = require("../../testkit")
local connector = require("init")

local TEST, CASE, CHECK, FINISH, SKIP = testkit.test()

local function NOOP() end

TEST("connector", function()
	do CASE("create connection")
		local connections = {}

		local connection = connector.connection(
			connections,
			NOOP
		)

		CHECK(
			table.find(connections, connection) ~= nil and
			table.isfrozen(connection :: any) and
			connection.f == NOOP and
			connection.connections == connections
		)
	end

	do CASE("disconnect connection")
		local connections = {}

		local connection = connector.connection(
			connections,
			NOOP
		)

		connection()

		CHECK(not table.find(connections, connection))
	end

	do CASE("run connections spawn")
		local conn1_got_correct_args = false
		local conn2_got_correct_args = false
		local conn3_got_correct_args = false
		local connections = {}

		local conn1 = connector.connection(
			connections,
			function(meow: string, mrrp: string)
				if meow == "mrrp" and mrrp == "meow" then
					conn1_got_correct_args = true
				end
			end
		)

		local conn2 = connector.connection(
			connections,
			function(meow: string, mrrp: string)
				if meow == "mrrp" and mrrp == "meow" then
					conn2_got_correct_args = true
				end
			end
		)

		local conn3 = connector.connection(
			connections,
			function(meow: string, mrrp: string)
				if meow == "mrrp" and mrrp == "meow" then
					conn3_got_correct_args = true
				end
			end
		)

		connector.spawn(connections, "mrrp", "meow")

		CHECK(
			testkit.seq(connections, { conn1, conn2, conn3 }) and
			conn1_got_correct_args and
			conn2_got_correct_args and
			conn3_got_correct_args
		)
	end

	do CASE("run connections defer")
		local conn1_got_correct_args
		local conn2_got_correct_args
		local conn3_got_correct_args
		local connections = {}

		local conn1 = connector.connection(
			connections,
			function(meow: string, mrrp: string)
				conn1_got_correct_args = meow == "mrrp" and mrrp == "meow"
			end
		)

		local conn2 = connector.connection(
			connections,
			function(meow: string, mrrp: string)
				conn2_got_correct_args = meow == "mrrp" and mrrp == "meow"
			end
		)

		local conn3 = connector.connection(
			connections,
			function(meow: string, mrrp: string)
				conn3_got_correct_args = meow == "mrrp" and mrrp == "meow"
			end
		)

		connector.defer(connections, "mrrp", "meow")

		while conn3_got_correct_args == nil do
			task.wait()
		end

		CHECK(
			testkit.seq(connections, { conn1, conn2, conn3 }) and
			conn1_got_correct_args and
			conn2_got_correct_args and
			conn3_got_correct_args
		)
	end
end)

assert(FINISH())
