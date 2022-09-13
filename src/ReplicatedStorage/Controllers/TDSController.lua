local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TDSCamera = require(ReplicatedStorage.Cameras.TDSCamera)

local MoveCharacter = require(ReplicatedStorage.Characters.MoveCharacter)
local TDSCharacter = require(ReplicatedStorage.Characters.TDSCharacter)

local TDSController = {}
TDSController.__index = TDSController

function TDSController.new(player, camera)
    local self = {
        player = player,
        mouse = player:GetMouse(),
        camera = TDSCamera.new(camera),

        weapons = {},

        characters = {},

        alive = false,

        connections = {}
    }

    setmetatable(self, TDSController)

    script.Connect:FireServer()
    self.weapons = script.GetWeapons:InvokeServer()

    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(character)
    end))
    table.insert(self.connections, self.player.CharacterRemoving:Connect(function()
        self:CharacterRemoving()
    end))

    if self.player.Character then
        self:CharacterAdded(self.player.Character)
    end

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
    table.insert(self.characters, MoveCharacter.new(self.mouse, character))
    table.insert(self.characters, TDSCharacter.new(self.weapons, character))

    TDSCamera:ChangeSubject(character)

    table.insert(self.connections, character.Humanoid.Died:Connect(function()
        self:Died()
    end))
    self.alive = true
end
function TDSController:CharacterRemoving()
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