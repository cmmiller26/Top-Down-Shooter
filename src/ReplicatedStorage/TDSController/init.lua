local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local TDSCamera = require(script.TDSCamera)
local TDSCharacter = require(script.TDSCharacter)

local MoveCharacter2D = require(Modules.MoveCharacter2D)

local TDSController = {}
TDSController.__index = TDSController

function TDSController.new(player, camera)
    local self = {
        player = player,
        mouse = player:GetMouse(),

        camera = nil,

        characters = {},

        connections = {},
    }
    setmetatable(self, TDSController)

    self.camera = TDSCamera.new(camera)

    self:LoadConnections()

    return self
end
function TDSController:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    self.camera:Destroy()
end

function TDSController:CharacterAdded(character)
    character:WaitForChild("Humanoid")

    self.camera:SetSubject(character)
    
    table.insert(self.characters, TDSCharacter.new(self, character))
    table.insert(self.characters, MoveCharacter2D.new(self, character))
end
function TDSController:CharacterRemoving()
    for _, character in ipairs(self.characters) do
        character:Destroy()
    end
    self.characters = {}
end

function TDSController:LoadConnections()
    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(character)
    end))
    table.insert(self.connections, self.player.CharacterRemoving:Connect(function()
        self:CharacterRemoving()
    end))
end

return TDSController