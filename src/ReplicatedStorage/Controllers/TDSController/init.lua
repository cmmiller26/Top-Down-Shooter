local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = ReplicatedStorage.Characters

local TDSCamera = require(ReplicatedStorage.Cameras.TDSCamera)

local MoveCharacter = require(Characters.MoveCharacter)
local TDSCharacter = require(Characters.TDSCharacter)

local Projectile = require(ReplicatedStorage.Modules.Projectile)

local TDSGui = require(script.TDSGui)

local TDSController = {}
TDSController.__index = TDSController

function TDSController.new(player, camera)
    local self = {
        player = player,
        mouse = player:GetMouse(),
        camera = nil,

        gui = nil,

        characters = {},
        alive = false,

        connections = {}
    }
    setmetatable(self, TDSController)

    script.Remotes.Connect:FireServer()

    self.camera = TDSCamera.new(camera)

    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(character)
    end))
    table.insert(self.connections, self.player.CharacterRemoving:Connect(function()
        self:CharacterRemoving()
    end))

    self:Remotes()

    return self
end
function TDSController:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    self.gui:Destroy()

    if next(self.characters) then
        self:Died()
    end
end

function TDSController:CharacterAdded(character)
    repeat wait() until character:FindFirstChild("Humanoid")

    self.camera:Subject(character)

    self.gui = TDSGui.new(self.player, self.camera, character)

    self.characters["Move"] = MoveCharacter.new(self.mouse, character)
    self.characters["TDS"] = TDSCharacter.new(self.gui, character)

    table.insert(self.connections, character.Humanoid.Died:Connect(function()
        self:Died()
    end))
    self.alive = true
end
function TDSController:CharacterRemoving()
    if self.alive then
        self:Died()
    end

    self.gui:Destroy()
end

function TDSController:Died()
    self.alive = false

    for _, character in pairs(self.characters) do
        character:Destroy()
    end
    self.characters = {}

    self.gui:Died()
end

function TDSController:Remotes()
    table.insert(self.connections, script.Remotes.ReplicateFire.OnClientEvent:Connect(function(character, item, velocity)
        item.PrimaryPart.Barrel.Flash:Emit(1)

        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        Projectile.new({
            origin = character.PrimaryPart.ProjectileSpawn.WorldPosition,
            velocity = velocity,
            distance = item.Settings.Distance.Value,
            raycastParams = raycastParams,
            meshPrefab = item.Effects.Projectile.Value
        })
    end))
end

return TDSController