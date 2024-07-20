
-- safe character added
-- simple utility function for running a function on character added for a player
-- and also if the player already has a character

export type Character = Model & {
    Humanoid: Humanoid & {
        HumanoidDescription: HumanoidDescription,
        Animator: Animator,
    },
    HumanoidRootPart: BasePart,
    BodyColors: BodyColors,
    Animate: LocalScript,
    Head: BasePart,
}

@checked
local function safe_character_added(
    player: Player,
    f: (character: Character) -> ()
): RBXScriptConnection
    local character = player.Character :: any

    if character then
        local thread = task.defer(f, character)

        player.CharacterRemoving:Once(function()
            pcall(task.cancel, thread)
        end)
    end

    return player.CharacterAdded:Connect(f :: any)
end

return safe_character_added