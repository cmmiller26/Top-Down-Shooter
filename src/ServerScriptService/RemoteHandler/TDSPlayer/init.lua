local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local HitboxHandler = require(ServerScriptService.HitboxHandler)

local Controller = ReplicatedStorage.Controllers.TDSController
local Character = ReplicatedStorage.Characters.TDSCharacter

local GetPlayerWeapons = require(script.GetPlayerWeapons)

local TDSPlayer = {}
TDSPlayer.__index = TDSPlayer

function TDSPlayer.new(player)
    local self = {
        player = player,
        weapons = nil,

        character = nil,

        curWeapon = nil,

        connections = {},
        functions = {}
    }

    setmetatable(self, TDSPlayer)

    local weapons = Instance.new("Folder")
    weapons.Name = "Weapons"
    weapons.Parent = self.player

    self.weapons = GetPlayerWeapons(self.player)
    for _, weapon in ipairs(self.weapons) do
        weapon.Parent = weapons
    end

    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(character)
    end))
    table.insert(self.connections, self.player.CharacterRemoving:Connect(function()
        self:CharacterRemoving()
    end))

    if self.player.Character then
        self:CharacterAdded(self.player.Character)
    end

    self:Remotes()

    return self
end
function TDSPlayer:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    for _, fnction in ipairs(self.functions) do
        fnction.OnServerInvoke = nil
    end
end

function TDSPlayer:CharacterAdded(character)
    self.character = character
    self.character.PrimaryPart = self.character:WaitForChild("HumanoidRootPart")

    local attach = Instance.new("Motor6D")
    attach.Name = "Attach"
    attach.Part0 = self.character:WaitForChild("Torso")
    attach.Parent = self.character.Torso

    for _, weapon in ipairs(self.weapons) do
        weapon.Holster.Part1 = self.character.Torso
        weapon.Parent = self.character
    end

    spawn(function()
        if not self.player:HasAppearanceLoaded() then
            self.player.CharacterAppearanceLoaded:Wait()
        end

        for _, accessory in ipairs(self.character:GetChildren()) do
            if accessory:IsA("Accessory") then
                local part = accessory:FindFirstChildWhichIsA("BasePart")
                if part then
                    part.CanQuery = false
                    part.CanTouch = false
                    PhysicsService:SetPartCollisionGroup(part, "NoCollide")
                end
            end
        end
    end)

    HitboxHandler:AddCharacter(self.character)
end
function TDSPlayer:CharacterRemoving()
    HitboxHandler:RemoveCharacter(self.character)

    self.character = nil
end

function TDSPlayer:Remotes()
    table.insert(self.functions, Controller.GetWeapons)
    Controller.GetWeapons.OnServerInvoke = function(player)
        if player == self.player then
            return self.weapons
        end
    end

    table.insert(self.connections, Character.Unequip.OnServerEvent:Connect(function(player)
        if player == self.player then
            if self.curWeapon and self.character then
                self.curWeapon.Holster.Enabled = true
                self.character.Torso.Attach.Part1 = nil
                self.curWeapon = nil
            end
        end
    end))
    table.insert(self.connections, Character.Equip.OnServerEvent:Connect(function(player, weapon)
        if player == self.player then
            if self.character and self.character:FindFirstChild("Humanoid") and self.character.Humanoid.Health > 0 then
                if weapon and weapon.Parent == self.character then
                    self.curWeapon = weapon
                    self.character.Torso.Attach.Part1 = self.curWeapon.PrimaryPart
                    self.curWeapon.Holster.Enabled = false
                end
            end
        end
    end))
end

return TDSPlayer