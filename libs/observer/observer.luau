--!strict

-- Observer
-- Simple observer library for roblox
-- note: the tool observers only observe equipped tools
-- @Kalrnlo
-- 13/04/2024

local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


export type Callback<T...> = ((T...) -> ()) & ((T...) -> (() -> ())?)
type TagConstructor<T...> = (tag: string, callback: Callback<T...>, dont_add_existing: boolean?) -> () -> ()
type Constructor<T...> = (callback: Callback<T...>, dont_add_existing: boolean?) -> () -> ()
type Map<T> = {[T]: () -> ()}

local function AddExistingObjectToMap(
	Connection: RBXScriptConnection,
	Map: Map<any>,
	Object: any,
	Callback: Callback<any>
)
	local CleanupCallback = Callback(Object) or nil

	if CleanupCallback then
		if Connection.Connected and Object then
			Map[Object] = CleanupCallback
		else
			CleanupCallback()
		end
	end
end

local function AddExistingToMap<T>(
	Connection: RBXScriptConnection,
	Map: Map<T>, 
	Objects: {T},
	Callback: Callback<T>
)
	for _, Object in Objects do
		if not Connection.Connected then 
            return 
        elseif not Object then
            continue
        elseif not Map[Object] then
            task.spawn(AddExistingObjectToMap, Connection, Map, Object, Callback)
        end
	end
end

local function CleanupMap(Map: Map<any>)
	for Key, Callback in Map do
		task.spawn(Callback)
		Map[Key] = nil
	end
end

local function LocalToolObserver(Tag: string, Callback: (Tool: Tool) -> () -> (), DontAddExisting: boolean?)
	if not RunService:IsClient() then
		error("[Observer] A LocalTool observer is only usable on the client")
	end
	local RemoveConnection: RBXScriptConnection
	local AddConnection: RBXScriptConnection
	local AddExistingThread: thread?
	local Map = {} :: Map<Tool>
	
	RemoveConnection = ContextActionService.LocalToolUnequipped:Connect(function(Tool)
		local CleanupCallback = Map[Tool]

		if CleanupCallback then
			Map[Tool] = nil
			CleanupCallback()
		end
	end)
	AddConnection = ContextActionService.LocalToolEquipped:Connect(function(Tool)
		if Tool:HasTag(Tag) then
			local CleanupCallback = Callback(Tool) or nil

			if CleanupCallback then
				if AddConnection.Connected and Tool then
					Map[Tool] = CleanupCallback
				else
					CleanupCallback()
				end
			end
		end
	end)

	if not DontAddExisting then
		local Character = Players.LocalPlayer.Character

		 if Character then
            AddExistingThread = task.defer(function(Character, AddConnection, Map, Callback, Tag)
			    for Index, Value in Character:GetChildren() do
					if not AddConnection.Connected then break end
					
				    if Value:IsA("Tool") and Value:HasTag(Tag) then
                        task.spawn(AddExistingObjectToMap, AddConnection, Map, Value, Callback)
				    end
			    end
		    end, Character, AddConnection, Map, Callback, Tag)
        end
	end

	return function()
		if AddExistingThread then
			task.cancel(AddExistingThread)
		end
		RemoveConnection:Disconnect()
		AddConnection:Disconnect()
		CleanupMap(Map)
	end
end

local function ObserveTool(Connection: RBXScriptConnection, Map: Map<Tool>, Callback: (Tool: Tool, Player: Player) -> () -> (), Tool: Tool, Player: Player)
	local CleanupCallback: (() -> ())?	
	local UnequippedConnection
	local DestroyingConnection

	UnequippedConnection = Tool.Unequipped:Once(function()
		if DestroyingConnection then
			DestroyingConnection:Disconnect()
		end
		if CleanupCallback then
			CleanupCallback()
		end
	end)
	DestroyingConnection = Tool.Destroying:Once(function()
		if UnequippedConnection then
			UnequippedConnection:Disconnect()
		end
		if CleanupCallback then
			CleanupCallback()
		end
	end)
	CleanupCallback = Callback(Tool, Player) or nil

	if CleanupCallback then
		if Connection.Connected and Tool then
			Map[Tool] = CleanupCallback
		else
			CleanupCallback()
		end
	end
end

local function ToolObserver(Tag: string, Callback: (Tool: Tool, Player: Player) -> () -> (), DontAddExisting: boolean?)
	local AddConnection: RBXScriptConnection
	local AddExistingThread: thread?
	local Map = {} :: Map<Tool>

	AddConnection = Players.PlayerAdded:Connect(function(Player)
		local CharacterConnection

		CharacterConnection = Player.CharacterAdded:Connect(function(Character)
			local ChildConnection

			if not AddConnection.Connected then
				CharacterConnection:Disconnect()
				return
			end

			ChildConnection = Character.ChildAdded:Connect(function(Child)
				if not AddConnection.Connected then
					CharacterConnection:Disconnect()
					ChildConnection:Disconnect()
					return
				elseif Child:HasTag(Tag) and Child:IsA("Tool") then
					ObserveTool(AddConnection, Map, Callback, Child :: Tool, Player)
				end
			end)
		end)
	end)

	if not DontAddExisting then
        AddExistingThread = task.defer(function(AddConnection, Map, Callback, Tag)
			for _, Player in Players:GetPlayers() do
				if not AddConnection.Connected then break end
				local Character = Player.Character

				if Character then
					task.spawn(function(Player, Character, Map, Callback, Tag)
						for Index, Value in Character:GetChildren() do
							if not AddConnection.Connected then break end

							if Value:IsA("Tool") and Value:HasTag(Tag) then
								task.spawn(ObserveTool, AddConnection, Map, Callback, Value, Player)
							end
						end
					end, Player, Character, Map, Callback, Tag)
				end
			end
		end, AddConnection, Map, Callback, Tag)
	end

	return function()
		if AddExistingThread then
			task.cancel(AddExistingThread)
		end
		AddConnection:Disconnect()
		CleanupMap(Map)
	end
end

local function tag_observer(tag: string, callback: (Instance: Instance) -> () -> (), dont_add_existing: boolean?)
	local remove_connection: RBXScriptConnection
	local add_connection: RBXScriptConnection
	local add_existing_thread: thread?
	local map = {} :: Map<Instance>
	
	remove_connection = CollectionService:GetInstanceRemovedSignal(tag):Connect(function(Object)
		local cleanup = map[Object]

		if cleanup then
			map[Object] = nil
			cleanup()
		end
	end)
	add_connection = CollectionService:GetInstanceAddedSignal(tag):Connect(function(Object)
		local cleanup = callback(Object)

		if add_connection.Connected and Object then
			map[Object] = cleanup
		else
			cleanup()
		end
	end)

	if not dont_add_existing then
		add_existing_thread = task.defer(
			AddExistingToMap,
			add_connection,
			map,
			CollectionService:GetTagged(tag), 
			callback
		)
	end

	return function()
		if add_existing_thread then
			task.cancel(add_existing_thread)
		end
		remove_connection:Disconnect()
		add_connection:Disconnect()
		CleanupMap(map)
	end
end

local function ObservePlayerForCharacter(Player: Player, Callback: Callback<Model, Player>)
	local RemoveConnection: RBXScriptConnection
	local AddConnection: RBXScriptConnection
	local CleanupCallback: (() -> ())?

	RemoveConnection = Player.CharacterRemoving:Connect(function(Character)
		if CleanupCallback then
			CleanupCallback()
		end
	end)
	AddConnection = Player.CharacterAdded:Connect(function(Character)
		CleanupCallback = Callback(Character, Player)
	
		if CleanupCallback and not AddConnection.Connected then
			CleanupCallback()
		end
	end)

	return function()		
		RemoveConnection:Disconnect()
		AddConnection:Disconnect()

		if CleanupCallback then
			CleanupCallback()
		end
	end
end

local function PlayerCharacterObserver(Callback: Callback<Model, Player>, DontAddExisting: boolean?)
	local AddExistingThread: thread?
	local Map = {} :: Map<Player>
	local AddConnection
	
	local RemovingConnection = Players.PlayerRemoving:Connect(function(Player)
		local CleanupCallback = Map[Player]

		if CleanupCallback then
			Map[Player] = nil
			CleanupCallback()
		end
	end)
	AddConnection = Players.PlayerAdded:Connect(function(Player)
		local CleanupCallback = ObservePlayerForCharacter(Player, Callback)
	
		if AddConnection.Connected and Player then
			Map[Player] = CleanupCallback
		else
			CleanupCallback()
		end
	end)

	if not DontAddExisting then
        AddExistingThread = task.defer(function(Connection, Map, Callback)
            for _, Player in Players:GetPlayers() do
                local CleanupCallback = ObservePlayerForCharacter(Player, Callback)

                if Connection.Connected and Player then
                    Map[Player] = CleanupCallback
                else
                    CleanupCallback()
                end
            end
        end, AddConnection, Map, Callback)
	end

	return function()
		if AddExistingThread then
			task.cancel(AddExistingThread)
		end
		
		RemovingConnection:Disconnect()
		AddConnection:Disconnect()
		CleanupMap(Map)
	end
end

local function PlayerObserver(Callback: Callback<Player>, DontAddExisting: boolean?)
	local RemoveConnection: RBXScriptConnection
	local AddConnection: RBXScriptConnection
	local AddExistingThread: thread?
	local Map = {} :: Map<Player>
	
	RemoveConnection = Players.PlayerRemoving:Connect(function(Player)
		local CleanupCallback = Map[Player]

		if CleanupCallback then
			Map[Player] = nil
			CleanupCallback()
		end
	end)
	AddConnection = Players.PlayerAdded:Connect(function(Player)
		local CleanupCallback = Callback(Player) or nil

		if CleanupCallback then
			if AddConnection.Connected and Player then
				Map[Player] = CleanupCallback
			else
				CleanupCallback()
			end
		end
	end)

	if not DontAddExisting then
		AddExistingThread = task.defer(
			AddExistingToMap,
			AddConnection,
			Map,
			Players:GetPlayers(), 
			Callback
		)
	end

	return function()
		if AddExistingThread then
			task.cancel(AddExistingThread)
		end
		RemoveConnection:Disconnect()
		AddConnection:Disconnect()
		CleanupMap(Map)
	end
end

local Exports = table.freeze {
    character = ObservePlayerForCharacter :: (player: Player, callback: Callback<Model, Player>) -> () -> (),
	character_and_player = PlayerCharacterObserver :: Constructor<Model, Player>,
	localtool = LocalToolObserver :: TagConstructor<Tool>,
    tool = ToolObserver :: TagConstructor<Tool, Player>,
	player = PlayerObserver :: :: Constructor<Player>,
	tag = TagObserver :: Constructor<Instance>,
}

return Exports