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
    tag: string,
    player: Player?
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
		if add_existing_thread then
			task.cancel(add_existing_thread)
		end
		remove_connection:Disconnect()
		add_connection:Disconnect()
		cleanup_map(map)
	end
end

local function observe_tool(
    connection: RBXScriptConnection,
    callback: (tool: Tool, player: Player) -> () -> (),
    map: Map<Tool>,
    tool: Tool, 
    player: Player
)
	local unequipped_connection: RBXScriptConnection
    local destroying_connection: RBXScriptConnection

	unequipped_connection = tool.Unequipped:Once(function()
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

	add_connection = Players.PlayerAdded:Connect(function(player)
		local character_connection

		character_connection = Player.CharacterAdded:Connect(function(Character)
			local child_connection

			if not add_connection.Connected then
				character_connection:Disconnect()
				return
			end

			child_connection = Character.ChildAdded:Connect(function(child)
				if not add_connection.Connected then
					character_connection:Disconnect()
					child_connection:Disconnect()
					return
				elseif child:HasTag(Tag) and child:IsA("Tool") then
					observe_tool(add_connection, callback, map, child, player)
				end
			end)
		end)
	end)

	if not dont_add_existing then
        add_existing_thread = task.defer(function(add_connection, map, callback, tag)
			for _, player in Players:GetPlayers() do
				if not add_connection.Connected then break end
				local character = player.Character

				if character then
					task.spawn(
                        add_existing_tools,
                        observe_tool,
                        add_connection,
                        callback,
                        map,
                        character,
                        tag,
                        player
                    )
				end
			end
		end, add_connection, map, callback, tag)
	end

	return function()
		if add_existing_thread then
			task.cancel(add_existing_thread)
		end
		add_connection:Disconnect()
		cleanup_map(map)
	end
end

local function tag_observer(tag: string, callback: (Instance: Instance) -> () -> (), dont_add_existing: boolean?)
	local remove_connection: RBXScriptConnection
	local add_connection: RBXScriptConnection
	local add_existing_thread: thread?
	local map = {} :: Map<Instance>
	
	remove_connection = CollectionService:GetInstanceRemovedSignal(tag):Connect(function(object)
        cleanup_object(map, object)
	end)
	add_connection = CollectionService:GetInstanceAddedSignal(tag):Connect(function(object)
        add_existing_object(add_connection, callback, map, object)
	end)

	if not dont_add_existing then
		add_existing_thread = task.defer(
			add_existing_objects,
			add_connection,
            callback,
			map,
			CollectionService:GetTagged(tag)
		)
	end

	return function()
		if add_existing_thread then
			task.cancel(add_existing_thread)
		end
		remove_connection:Disconnect()
		add_connection:Disconnect()
		cleanup_map(map)
	end
end

local function observe_player_for_character(player: Player, callback: (character: Model, player: Player) -> () -> ())
	local remove_connection: RBXScriptConnection
	local add_connection: RBXScriptConnection
	local cleanup: (() -> ())?

	remove_connection = Player.CharacterRemoving:Connect(function()
		if cleanup then
			cleanup()
		end
	end)
	add_connection = player.CharacterAdded:Connect(function(character)
		cleanup = callback(character, player)
	
		if not add_connection.Connected then
			cleanup()
		end
	end)

	return function()		
		remove_connection:Disconnect()
		add_connection:Disconnect()

		if cleanup then
			cleanup()
		end
	end
end

local function character_player_observer(callback: (character: Model, player: Player) -> () -> (), dont_add_existing: boolean?)
	local remove_connection: RBXScriptConnection
	local add_connection: RBXScriptConnection
	local add_existing_thread: thread?
	local map = {} :: Map<Player>
	
	remove_connection = Players.PlayerRemoving:Connect(function(player)
		local cleanup = map[player]

		if cleanup then
			map[player] = nil
			cleanup()
		end
	end)
	add_connection = Players.PlayerAdded:Connect(function(Player)
		local cleanup = observe_player_for_character(player, callback)
	
		if add_connection.Connected and player then
			map[player] = cleanup
		else
			cleanup()
		end
	end)

	if not dont_add_existing then
        add_existing_thread = task.defer(function(add_connection, map, callback)
            for _, player in Players:GetPlayers() do
				local cleanup = observe_player_for_character(player, callback)
	
				if add_connection.Connected and player then
					map[player] = cleanup
				else
					cleanup()
				end
            end
        end, add_connection, map, callback)
	end

	return function()
		if add_existing_thread then
			task.cancel(add_existing_thread)
		end
		
		remove_connection:Disconnect()
		add_connection:Disconnect()
		cleanup_map(map)
	end
end

local function player_observer(callback: (player: Player) -> () -> (), dont_add_existing: boolean?)
	local remove_connection: RBXScriptConnection
	local add_connection: RBXScriptConnection
	local add_existing_thread: thread?
	local map = {} :: Map<Player>
	
	remove_connection = Players.PlayerRemoving:Connect(function(player)
        cleanup_object(map, player)
	end)
	add_connection = Players.PlayerAdded:Connect(function(player)
        add_existing_object(add_connection, callback, map, player)
	end)

	if not dont_add_existing then
		add_existing_thread = task.defer(
			add_existing_objects,
			add_connection,
            callback,
			map,
			Players:GetPlayers()
		)
	end

	return function()
		if add_existing_thread then
			task.cancel(add_existing_thread)
		end
		remove_connection:Disconnect()
		add_connection:Disconnect()
		cleanup_map(map)
	end
end

local exports = table.freeze {
	character = player_character_observer,
	localtool = localtool_observer,
	player = player_observer,
	tool = tool_observer,
	tag = tag_observer,
}

return exports