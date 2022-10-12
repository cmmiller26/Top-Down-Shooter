local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Debug = require(ReplicatedStorage.Debug)

local HitboxHandler = require(ServerScriptService.HitboxHandler)

local FireState = require(script.FireState)

local Controller = ReplicatedStorage.Controllers.TDSController
local Character = ReplicatedStorage.Characters.TDSCharacter

local GetPlayerWeapons = require(script.GetPlayerWeapons)

local HitboxCharacter = ReplicatedStorage.HitboxCharacter

local PROJECTILE_OFFSET = 0.5

local ORIGIN_ERROR = 5
local HIT_POS_ERROR = 1
local SPEED_ERROR = 2

local TDSPlayer = {}
TDSPlayer.__index = TDSPlayer

function TDSPlayer.new(player)
    local self = {
        player = player,
        weapons = nil,

        character = nil,

        curWeapon = nil,

        fireStates = {},

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

    self:Remotes()

    -- REMOVE LATER: Spawn character
    spawn(function()
        wait(1)
        self.player:LoadCharacter()
    end)

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
    self.character.PrimaryPart.CanQuery = false
    self.character.PrimaryPart.CanTouch = false

    self.character:WaitForChild("Humanoid").BreakJointsOnDeath = false
    self.character.Humanoid.Died:Connect(function()
        -- REMOVE LATER: Respawn
        wait(5)
        self.player:LoadCharacter()
    end)

    local attach = Instance.new("Motor6D")
    attach.Name = "Attach"
    attach.Part0 = self.character:WaitForChild("Torso")
    attach.Parent = self.character.Torso

    for _, weapon in ipairs(self.weapons) do
        weapon.Holster.Part1 = self.character.Torso
        weapon.Parent = self.character
    end

    local projectileSpawn = Instance.new("Attachment")
    projectileSpawn.Name = "ProjectileSpawn"
    projectileSpawn.Position = Vector3.new(0, PROJECTILE_OFFSET, 0)
    projectileSpawn.Parent = self.character.PrimaryPart

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

    for _, weapon in ipairs(self.weapons) do
        weapon.Parent = self.player.Weapons
        weapon.Holster.Part1 = nil
    end

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

    table.insert(self.connections, Character.Fire.OnServerEvent:Connect(function(player, origin, direction, fireID, playerTick)
        if player == self.player then
            if self.character and self.character:FindFirstChild("Humanoid") and self.character.Humanoid.Health > 0 then
                local pastPos = self.character.PrimaryPart.Position + Vector3.new(0, PROJECTILE_OFFSET, 0)
                Debug.Vector(origin, pastPos, Color3.new(0, 0, 1))
                print((origin - pastPos).Magnitude)
                if (origin - pastPos).Magnitude <= ORIGIN_ERROR then
                    self.fireStates[fireID] = FireState.new(
                        origin,
                        direction.Unit * self.curWeapon.Settings.Distance.Value,
                        self.curWeapon.Settings.Speed.Value,
                        self.curWeapon.Settings.Damage.Value,
                        playerTick
                    )

                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {self.character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        if otherPlayer ~= self.player then
                            print("Bullet Replicated")
                            Character.Fire:FireClient(otherPlayer, {
                                origin = origin,
                                velocity = direction.Unit * self.curWeapon.Settings.Distance.Value,
                                distance = self.curWeapon.Settings.Distance.Value,
                                raycastParams = raycastParams,
                                meshPrefab = self.curWeapon.Effects.Projectile.Value,
                                meshPos = self.curWeapon.PrimaryPart.Barrel.WorldPosition
                            })
                        end
                    end
                end
            end
        end
    end))
    table.insert(self.connections, Character.Hit.OnServerEvent:Connect(function(player, hit, hitCFrame, fireID, playerTick)
        if player == self.player then
            if hit and hit.Parent:FindFirstChildWhichIsA("Humanoid") then
                local fireState = self.fireStates[fireID]
                local hitboxState = HitboxHandler:GetHitboxState(hit.Parent, playerTick)
                if fireState and hitboxState and hitboxState[hit.Name] then
                    local serverCFrame = hitboxState[hit.Name]
                    if (hitCFrame.Position - serverCFrame.Position).Magnitude <= HIT_POS_ERROR then
                        local hitbox = HitboxCharacter:FindFirstChild(hit.Name):Clone()
                        hitbox.CFrame = hitCFrame
                        hitbox.Parent = workspace
                        repeat wait() until hitbox.Parent == workspace

                        local raycastParams = RaycastParams.new()
                        raycastParams.CollisionGroup = "Hitbox"
                        raycastParams.FilterDescendantsInstances = {hitbox}
                        raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

                        local raycastResult = workspace:Raycast(fireState.origin, fireState.direction, raycastParams)
                        if raycastResult then
                            Debug.Vector(fireState.origin, raycastResult.Position, Color3.new(0, 1, 1))
                            local distance = (raycastResult.Position - fireState.origin).Magnitude
                            if distance / fireState.speed <= (playerTick - fireState.playerTick) * SPEED_ERROR then
                                hit.Parent.Humanoid:TakeDamage(fireState.damage)
                            end
                        end

                        Debris:AddItem(hitbox, 2)
                        --hitbox:Destroy()
                    end
                end
            end
        end
    end))
end

return TDSPlayer