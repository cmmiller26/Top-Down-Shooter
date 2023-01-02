local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerRemotes = ReplicatedStorage.TDSController.Remotes
local CharacterRemotes = ReplicatedStorage.TDSCharacter.Remotes

local TDSPlayer = {}
TDSPlayer.__index = TDSPlayer

function TDSPlayer.new(player)
    local self = {
        player = player,
    }
    setmetatable(self, TDSPlayer)

    ControllerRemotes.Connect:FireClient(player)

    return self
end
function TDSPlayer:Destroy()

end

return TDSPlayer