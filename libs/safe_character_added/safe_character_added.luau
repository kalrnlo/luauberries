
-- safe character added
-- simple utility function for running a function on character added for a player
-- and also if the player already has a character

@checked
local function safe_character_added(
    player: Player,
    f: (character: Model & { Humanoid: Humanoid? }) -> ()
): RBXScriptConnection
    local character = player.Character :: any

    if character then
        local thread = task.defer(f, character)

        player.CharacterRemoving:Once(function()
            pcall(task.cancel, thread)
        end)
    end

    return player.CharacterAdded:Connect(function(character: any)
        f(character)
    end)
end

return safe_character_added