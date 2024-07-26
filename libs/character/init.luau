
-- character
-- simple utility module for getting accurate character types,
-- and with a special added function that also runs the callback
-- if the player already has a character

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

local character = {}

function character.removing(player: Player, f: (Character: Character) -> ()): RBXScriptConnection
	return player.CharacterRemoving:Connect(f :: any)
end

function character.added(player: Player, f: (Character: Character) -> ()): RBXScriptConnection
	local character = player.Character :: any

	if character then
		local thread = task.defer(f, character)

		player.CharacterRemoving:Once(function()
			pcall(task.cancel, thread)
		end)
	end

	return player.CharacterAdded:Connect(f :: any)
end

-- this function exists so u dont have to do
-- local character = (player.Character :: any) :: character.Character?
function character.get(player: Player): Character?
	return player.Character :: any
end

return table.freeze(character)