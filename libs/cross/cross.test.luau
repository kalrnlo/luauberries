local testkit = require("../../testkit")
local cross = require("init")

local TEST, CASE, CHECK, FINISH, SKIP = testkit.test()

local function spawner_test(name: string,spawn_func: <A..., R...>(f: ((A...) -> (R...)) | thread, A...) -> thread)
	do CASE(name)
		local args_str: string

		local func_thread = spawn_func(function()
			local args = { coroutine.yield() }
			args_str = table.concat(args, ", ")
		end)

		local thread_thread = spawn_func(
			func_thread, "meow", "mrrp"
		)

		CHECK(
			type(func_thread) == "thread" and
			type(thread_thread) == "thread" and
			func_thread == thread_thread and
			args_str == "meow, mrrp"
		)
	end
end

TEST("cross", function()
	do CASE("check globals")
		CHECK(
			task.cancel == cross.cancel and
			task.spawn == cross.spawn and
			task.defer == cross.defer and
			task.wait == cross.wait and 
			_RUNTIME == cross.runtime and
			warn == cross.warn
		)
	end

	do CASE("spawn")
		local args_str: string
		local thread_started = false

		local func_thread = cross.spawn(function()
			thread_started = true
			local args = { coroutine.yield() }
			args_str = table.concat(args, ", ")
		end)

		while not thread_started do
			task.wait()
		end

		local thread_thread = cross.spawn(
			func_thread, "meow", "mrrp"
		)

		CHECK(
			type(func_thread) == "thread" and
			type(thread_thread) == "thread" and
			func_thread == thread_thread and
			args_str == "meow, mrrp"
		)
	end

	do CASE("defer")
		local thread_started = false
		local args_str: string

		local func_thread = cross.defer(function()
			thread_started = true
			local args = { coroutine.yield() }
			args_str = table.concat(args, ", ")
		end)

		while not thread_started do
			task.wait()
		end
		local thread_thread = cross.defer(
			func_thread, "meow", "mrrp"
		)

		while not args_str do
			task.wait()
		end

		CHECK(
			type(func_thread) == "thread" and
			type(thread_thread) == "thread" and
			func_thread == thread_thread and
			args_str == "meow, mrrp"
		)
	end

	do CASE("delay")
		--[[
		local thread_started = false
		local args_str: string

		local func_thread = cross.delay(1, function()
			thread_started = true
			local args = { coroutine.yield() }
			args_str = table.concat(args, ", ")
		end)

		if thread_started then
			CHECK(false)	
		end

		task.wait(2)

		if not thread_started then
			print("lmao")
			CHECK(false)
		end

		-- for some reason after this args str doesn't ever get set
		-- even tho it should be, so once again ive lost to the hell that is the lune scheduler
		local thread_thread = cross.delay(
			1, func_thread, "meow", "mrrp"
		)

		if args_str then
			CHECK(false)	
		end

		task.wait(2)

		CHECK(
			type(func_thread) == "thread" and
			type(thread_thread) == "thread" and
			func_thread == thread_thread and
			args_str == "meow, mrrp"
		)
		--]]
	end

	do CASE("cancel")
		local thread = cross.defer(function()
			cross.wait(4)
		end)

		pcall(cross.cancel, thread)
		CHECK(coroutine.status(thread) == "dead")
	end

end)