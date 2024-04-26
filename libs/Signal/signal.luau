--!optimize 2
--!nocheck
--!native

-- Signal
-- yet another signal module although without ordering,
-- infact this signal is so anti-ordering that it uses swap removal
-- based on roblox's signal-lua and LemonSignal.
-- @Kalrnlo
-- 23/04/2024

local Metaize = require "@kalrnlo/metaize"

type Sender<values...> = typeof(setmetatable({} :: {Signal<values...>}, {} :: SenderPrototype<values...>))

type Connection<values...> = typeof(setmetatable({} :: {
	["1"]: (values...) -> (),
	["2"]: Signal<values...>,
	["3"]: boolean?,
}, {} :: ConnectionPrototype<values...>))

type ConnectionPrototype<values...> = {
	__call: (self: Connection<values...>) -> ()
}

type SenderPrototype<values...> = {
	__call: (self: Sender<values...>, values...) -> ()
}

export type ValueReuseSignal<value> = ValueSignal<value> & ReuseSignal<value>

export type ValueSignal<value> = Signal<value> & {value: value}

export type Signal<values...> = {
	subscribe: (self: Signal<values...>, Callback: (values...) -> ()) -> () -> (),
	once: (self: Signal<values...>, Callback: (values...) -> ()) -> () -> (),
	connections: {Connection<values...> | thread},
	wait: (self: Signal<values...>) -> values...,
}

export type ReuseSignal<values...> = Signal<values...> & {
	free_threads: {thread}
}

local function Resume<T...>(ThreadOrCallback: thread | (...T) -> (), ...: T...)
	local Thread = if type(ThreadOrCallback) == "thread" then
			ThreadOrCallback
		else
			coroutine.create(ThreadOrCallback)

	local Success, Message = coroutine.resume(Thread, ...)

	if Success == false then
		coroutine.wrap(error)(
			debug.traceback(`[Signal] Could not resume thread, Message: {Message}`, 3), 3
		)
	end
end

local TaskSpawn = if task then task.spawn else Resume

local function run_callback<values...>(free_threads: {thread}, thread: thread, callback: (...values) -> (), ...: values)
	callback(...)
	free_threads[#free_threads + 1] = thread
end

local function Yielder()
	while true do
		run_callback(coroutine.yield())
	end
end

--------------------------------------------------------------------------------
-- Connection
--------------------------------------------------------------------------------

local function Connection_Call<T...>(self: Connection<T...>)
	local Signal = self[2] :: Signal<T...>
	local Index = table.find(Signal.connections, self)

	if Index then
		local Length = #Signal.connections

		if Length > 1 then
			Signal.connections[Index] = Signal.connections[Length]
			Signal.connections[Length] = nil
		else
			Signal.connections[Index] = nil
		end
	end
end

local ConnectionPrototype = Metaize {
	__call = Connection_Call,
}

--------------------------------------------------------------------------------
-- Sender
-------------------------------------------------------------------------------- 

local function ReuseRunConnections<T...>(Signal: ReuseSignal<T...>, ...: T)
	local Connections = Signal.connections
	local FreeThreads = Signal.free_threads

	for Index, ConnectionOrThread in Connections do
		if type(ConnectionOrThread) == "table" then 
			local Callback: (...T) -> () = ConnectionOrThread[1] :: any

			if #FreeThreads > 0 then
				local Thread = FreeThreads[#FreeThreads]
				FreeThreads[#FreeThreads] = nil
				TaskSpawn(Thread, FreeThreads, Thread, Callback, ...)
			else
				local Thread = coroutine.create(Yielder)
				coroutine.resume(Thread)
				TaskSpawn(Thread, FreeThreads, Thread, Callback, ...)
			end

			if #ConnectionOrThread == 3 then
				if #Connections > 1 then
					Connections[Index] = Connections[#Connections]
					Connections[#Connections] = nil
				else
					Connections[Index] = nil
				end
			end
		else
			TaskSpawn(ConnectionOrThread, ...)

			if #Connections > 1 then
				Connections[Index] = Connections[#Connections]
				Connections[#Connections] = nil
			else
				Connections[Index] = nil
				return
			end
		end
	end
end

local function RunConnections<T...>(Connections: {Connection<T...> | thread}, ...: T)
	for Index, ConnectionOrThread in Connections do
		if type(ConnectionOrThread) == "table" then 
			TaskSpawn(ConnectionOrThread[1] :: any, ...)

			if #ConnectionOrThread == 3 then
				if #Connections > 1 then
					Connections[Index] = Connections[#Connections]
					Connections[#Connections] = nil
				else
					Connections[Index] = nil
				end
			end
		else
			TaskSpawn(ConnectionOrThread, ...)

			if #Connections > 1 then
				Connections[Index] = Connections[#Connections]
				Connections[#Connections] = nil
			else
				Connections[Index] = nil
				return
			end
		end
	end
end

local function ReuseValueSender_Call<T>(self: Sender<T>, Value: T)
	local Signal = self[1]

	if Value ~= Signal.value then
		Signal.value = Value
		ReuseRunConnections(Signal, Value)
	end
end

local function ReuseSender_Call<T...>(self: Sender<T...>, ...: T)
	ReuseRunConnections(self[1], ...)
end

local function ValueSender_Call<T>(self: Sender<T>, Value: T)
	local Signal = self[1]

	if Value ~= Signal.value then
		Signal.value = Value
		RunConnections(Signal.connections, Value)
	end
end

local function Sender_Call<T...>(self: Sender<T...>, ...: T)
	RunConnections(self[1].connections, ...)
end

local ReuseValueSenderPrototype = Metaize {
	__call = ReuseValueSender_Call,
}

local ReuseSenderPrototype = Metaize {
	__call = ReuseSender_Call,
}

local ValueSenderPrototype = Metaize {
	__call = ValueSender_Call,
}

local SenderPrototype = Metaize {
	__call = Sender_Call,
}

--------------------------------------------------------------------------------
-- Signal
--------------------------------------------------------------------------------

local function Signal_Subscribe<T...>(self: Signal<T...>, Callback: Callback<T...>)
	local Refrences = table.create(2)
	Refrences[1] = Callback
	Refrences[2] = self

	local Connection = setmetatable(Refrences, ConnectionPrototype)
	self.connections[#self.connections + 1] = Connection
	return Connection
end

local function Signal_Once<T...>(self: Signal<T...>, Callback: Callback<T...>)
	local Refrences = table.create(3)
	Refrences[1] = Callback
	Refrences[2] = self
	Refrences[3] = true

	local Connection = setmetatable(Refrences, ConnectionPrototype)
	self.connections[#self.connections + 1] = Connection
	return Connection
end

local function Signal_Wait<T...>(self: Signal<T...>)
	self.connections[#self.connections + 1] = coroutine.running()
	return coroutine.yield()
end

local SignalPrototype = Metaize {
	subscribe = Signal_Subscribe,
	once = Signal_Once,
	wait = Signal_Wait,
}

local function CreateValueSignal<Value>(Value: Value?, ReuseThreads: boolean?, PreAllocateThreads: number?): (ValueSignal<Value>, (NewValue: Value) -> ())
	if ReuseThreads then
		if PreAllocateThreads then
			if PreAllocateThreads < 1 then
				error("[Signal] PreAllocateThreads cannot be less than 1")
			end
			local FreeThreads = table.create(PreAllocateThreads)
			local self = setmetatable({
				connections = table.create(PreAllocateThreads),
				free_threads = FreeThreads,
				value = Value,
			}, SignalPrototype)

			for Index = 1, PreAllocateThreads do
				FreeThreads[Index] = coroutine.create(Yielder)
			end

			return self, setmetatable(table.create(1, self), ReuseValueSenderPrototype)
		else
			local self = setmetatable({
				free_threads = {},
				connections = {},
				value = Value,
			}, SignalPrototype)

			return self, setmetatable(table.create(1, self), ReuseValueSenderPrototype)
		end
	else
		local self = setmetatable({connections = {}, value = Value}, SignalPrototype)
		return self, setmetatable(table.create(1, self), ValueSenderPrototype)
	end
end

local function CreateSignal<T...>(ReuseThreads: boolean?, PreAllocateThreads: number?): (Signal<T...>, (...T) -> ())
	if ReuseThreads then
		if PreAllocateThreads then
			if PreAllocateThreads < 1 then
				error("[Signal] PreAllocateThreads cannot be less than 1")
			end
			local FreeThreads = table.create(PreAllocateThreads)
			local self = setmetatable({
				connections = table.create(PreAllocateThreads),
				free_threads = FreeThreads,
			}, SignalPrototype)

			for Index = 1, PreAllocateThreads do
				FreeThreads[Index] = coroutine.create(Yielder)
			end

			return self, setmetatable(table.create(1, self), ReuseSenderPrototype)
		else
			local self = setmetatable({
				free_threads = {},
				connections = {},
			}, SignalPrototype)

			return self, setmetatable(table.create(1, self), ReuseSenderPrototype)
		end
	else
		local self = setmetatable({connections = {}}, SignalPrototype)
		return self, setmetatable(table.create(1, self), SenderPrototype)
	end
end

local Exports = table.freeze {
	value = CreateValueSignal :: (<value>(value: value?) -> (ValueSignal<value>, (new: value) -> ())) & 
		(<value>(value: value?, reuse_threads: true, pre_allocate_threads: number?) -> (ValueReuseSignal<value>, (new: value) -> ())),
	create = (CreateSignal :: any) :: (<values...>() -> (Signal<...values>, (values...) -> ())) & 
		(<values...>(reuse_threads: true, pre_allocate_threads: number?) -> (ReuseSignal<values...>, (values...) -> ())),
}

return Exports
