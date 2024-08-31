
-- rbxsafeconn
-- utility for safely connecting to commonly used events where you'd also iterate through some instances

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local character = require("../character")

local PLAYER_ADDED = Players.PlayerAdded

local rbx_event = {}

-- uses a generic so u can cast instance in the callback to any instance,
-- as generally u know what instance a tag takes in, and the callback would probably error anyways
-- if it didnt take in that specific instance
function rbx_event.tag_added<I>(tag: string, f: (instance: I & Instance) -> ()): () -> ()
	local conn = CollectionService:GetInstanceAddedSignal(tag):Connect(f :: any)

	for _, instance: any in CollectionService:GetTagged(tag) do
		task.spawn(f, instance)
	end

	return function()
		conn:Disconnect()
	end
end

function rbx_event.player_added(
	f: (player: Player & { Character: character.Character? }) -> ()
): () -> ()
	local conn = PLAYER_ADDED:Connect(f :: any)

	for _, player: any in Players:GetPlayers() do
		task.spawn(f, player)
	end

	return function()
		conn:Disconnect()
	end
end

return table.freeze(rbx_event)