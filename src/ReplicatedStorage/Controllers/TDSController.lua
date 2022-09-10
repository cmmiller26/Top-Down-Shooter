local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TDSCharacter = require(ReplicatedStorage.Characters.TDSCharacter)

local TDSController = {}
TDSController.__index = TDSController

function TDSController.new(player, camera)
    local self = {
        player = player,
        camera = camera,

        characters = {},

        alive = false,

        connections = {}
    }

    setmetatable(self, TDSController)

    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(character)
    end))
    table.insert(self.connections, self.player.CharacterRemoving:Connect(function(character)
        self:CharacterRemoving(character)
    end))

    return self
end
function TDSController:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    if next(self.characters) then
        self:Died()
    end
end

function TDSController:CharacterAdded(character)
    table.insert(self.characters, TDSCharacter.new(self.camera, character))

    table.insert(self.connections, character.Humanoid.Died:Connect(function()
        self:Died()
    end))
    self.alive = true
end
function TDSController:CharacterRemoving(character)
    if self.alive then
        self:Died()
    end
end

function TDSController:Died()
    self.alive = false

    for _, character in ipairs(self.characters) do
        character:Destroy()
    end
    self.characters = {}
end

return TDSController