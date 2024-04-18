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

type Map<T> = {[T]: () -> ()}

local function add_existing_object<T>(
	connection: RBXScriptConnection,
    callback: (T) -> () -> (),
    map: Map<T>,
	object: T
)
	local cleanup = callback(object)

	if connection.Connected and object then
		map[object] = cleanup
	else
		cleanup()
	end
end

local function add_existing_objects<T>(
	connection: RBXScriptConnection,
    callback: (T) -> () -> (),
	map: Map<T>, 
	objects: {T}
)
	for _, object in objects do
		if not connection.Connected then 
            return 
        elseif not object then
            continue
        elseif not map[object] then
            task.spawn(add_existing_object, connection, callback, map, object)
        end
	end
end

local function cleanup_object<T>(map: Map<T>, object: T)
    local cleanup = map[object]

    if cleanup then
        map[object] = nil
        cleanup()
    end
end

local function cleanup_map<T>(map: Map<T>)
	for object, cleanup in map do
		task.spawn(cleanup)
		map[key] = nil
	end
end

local function add_existing_tools<T>(
    add_callback: any,
    connection: RBXScriptConnection,
    observe_callback: (T) -> () -> (),
	map: Map<T>,
    character: Model,
    tag: string
)
    for _, child in character:GetChildren() do
        if not connection.Connected then
            break
        elseif child:IsA("Tool") and child:HasTag(tag) then
            task.spawn(add_callback, connection, callback, map, child, player)
        end
    end
end

local function localtool_observer(tag: string, callback: (tool: tool) -> () -> (), dont_add_existing: boolean?)
	if not RunService:IsClient() then
		error("[Observer] A LocalTool observer is only usable on the client")
	end
	local remove_connection: RBXScriptConnection
	local add_connection: RBXScriptConnection
	local add_existing_thread: thread?
	local map = {} :: Map<Tool>
	
	remove_connection = ContextActionService.LocalToolUnequipped:Connect(function(tool)
        cleanup_object(map, tool)
	end)
	add_connection = ContextActionService.LocalToolEquipped:Connect(function(tool)
		if tool:HasTag(tag) then
            add_existing_object(add_connection, callback, map, tool)
		end
	end)

	if not dont_add_existing then
		local character = Players.LocalPlayer.Character

		 if character then
            add_existing_thread = task.defer(
                add_existing_tools,
                add_existing_object,
                add_connection,
                callback,
                map,
                character,
                tag
            )
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

local function observe_tool(
    connection: RBXScriptConnection,
    callback: (tool: Tool, player: Player) -> () -> (),
    map: Map<Tool>,
    tool: Tool, 
    player: Player
)
    local destroying_connection: RBXScriptConnection

	local unequipped_connection = tool.Unequipped:Once(function()
		if destroying_connection then
			destroying_connection:Disconnect()
		end
		if cleanup then
			cleanup()
		end
	end)
	destroying_connection = tool.Destroying:Once(function()
		if unequipped_connection then
			unequipped_connection:Disconnect()
		end
        cleanup_object(map, tool)
	end)

	local cleanup = callback(tool, player)

	if connection.Connected and tool then
		map[tool] = cleanup
	else
		cleanup
	end
end

local function tool_observer(tag: string, callback: (tool: Tool, player: Player) -> () -> (), dont_add_existing: boolean?)
	local add_connection: RBXScriptConnection
	local add_existing_thread: thread?
	local map = {} :: Map<Tool>

	AddConnection = Players.PlayerAdded:Connect(function(player)
		local character_connection

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

local function observe_player_for_character(Player: Player, Callback: Callback<Model, Player>)
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

local function character_player_observer(Callback: Callback<Model, Player>, DontAddExisting: boolean?)
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
		local CleanupCallback = observe_player_for_character(Player, Callback)
	
		if AddConnection.Connected and Player then
			Map[Player] = CleanupCallback
		else
			CleanupCallback()
		end
	end)

	if not DontAddExisting then
        AddExistingThread = task.defer(function(Connection, Map, Callback)
            for _, Player in Players:GetPlayers() do
                local CleanupCallback = observe_player_for_character(Player, Callback)

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
    character = ObservePlayerForCharacter,
	character_and_player = player_character_observer :: Constructor<Model, Player>,
	localtool = localtool_observer,
    tool = tool_observer,
	player = player_observer :: :: Constructor<Player>,
	tag = tag_observer :: Constructor<Instance>,
}

return Exports