
-- character
-- simple utility module for getting accurate character types,
-- and with a special added function that also runs the callback
-- if the player already has a character

local Players = game:GetService("Players")

export type Character = Model & {
    Humanoid: Humanoid & {
        HumanoidDescription: HumanoidDescription,
        Animator: Animator,
    },
    HumanoidRootPart: BasePart,
    BodyColors: BodyColors,
	PrimaryPart: BasePart,
    Animate: LocalScript,
    Head: BasePart,
}

--[[
Maps players to their characters (which have their appearance loaded)
]]
local characterAppearanceLoaded: {Player: Character?} = {}
do 
	local function playerAdded(player: Player)
		player.CharacterAppearanceLoaded:Connect(function(character: any)
			characterAppearanceLoaded[player] = character
		end)

		player.CharacterRemoving:Connect(function()
			characterAppearanceLoaded[player] = nil
		end)
	end

	local function PlayerRemoving(player: Player)
		characterAppearanceLoaded[player] = nil
	end

	Players.PlayerRemoving:Connect(PlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end
	Players.PlayerAdded:Connect(playerAdded)
end

local character = {}

function character.removing_once(player: Player, f: (character: Character) -> ()): () -> ()
	local removing_conn = player.CharacterRemoving:Once(f :: any)

	return function()
		if removing_conn.Connected then
			removing_conn:Disconnect()
		end
	end
end

function character.removing(player: Player, f: (character: Character) -> ()): () -> ()
	local removing_conn = player.CharacterRemoving:Connect(f :: any)

	return function()
		removing_conn:Disconnect()
	end
end

function character.added(
	player: Player,
	f: (character: Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local character = character.get(player)
	local removing_conn: RBXScriptConnection?
	local thread: thread

	if character and not dont_run_for_existing_character then
		thread = task.defer(f, character)

		removing_conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)
	end

	local added_conn = player.CharacterAdded:Connect(f :: any)

	return function()
		if removing_conn and removing_conn.Connected then
			removing_conn:Disconnect()
		end

		if added_conn then
			added_conn:Disconnect()
		end

		coroutine.close(thread)
	end
end

function character.added_once(
	player: Player,
	f: (character: Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local character = character.get(player)

	if character and not dont_run_for_existing_character then
		local thread = task.defer(f, character)

		local conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
			coroutine.close(thread)
		end
	else
		local conn = player.CharacterAdded:Once(f :: any)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
		end
	end
end

function character.appearance_loaded(
	player: Player,
	f: (character: Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local character = character.get_appearance_loaded(player)
	local removing_conn: RBXScriptConnection?
	local thread: thread

	if character and not dont_run_for_existing_character then
		thread = task.defer(f, character)

		removing_conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)
	end

	local added_conn = player.CharacterAppearanceLoaded:Connect(f :: any)

	return function()
		if removing_conn and removing_conn.Connected then
			removing_conn:Disconnect()
		end

		if added_conn then
			added_conn:Disconnect()
		end

		coroutine.close(thread)
	end
end

function character.appearance_loaded_once(
	player: Player,
	f: (character: Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local character = character.get_appearance_loaded(player)

	if character and not dont_run_for_existing_character then
		local thread = task.defer(f, character)

		local conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
			coroutine.close(thread)
		end
	else
		local conn = player.CharacterAppearanceLoaded:Once(f :: any)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
		end
	end
end

-- this function exists so u dont have to do
-- local character = (player.Character :: any) :: character.Character?
function character.get(player: Player): Character?
	return player.Character :: any
end

function character.get_appearance_loaded(player: Player): Character?
	return characterAppearanceLoaded[player]
end

return table.freeze(character)
