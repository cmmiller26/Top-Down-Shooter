local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local PingTimes = require(ReplicatedStorage.PingTimes)
local Debug = require(ReplicatedStorage.Modules.Debug)

local HitboxHandler = require(ServerScriptService.HitboxHandler)
local FireState = require(script.FireState)

local Items = ServerStorage.Items

local ControllerRemotes = ReplicatedStorage.Controllers.TDSController.Remotes
local CharacterRemotes = ReplicatedStorage.Characters.TDSCharacter.Remotes

local HitboxCharacter = ReplicatedStorage.HitboxCharacter

local MAX_HEALTH = 100
local MAX_SHIELD = 100

local MAX_ITEMS = 5

local MAX_PICKUP_DISTANCE = 4
local ITEM_RADIUS = 1

local PROJECTILE_OFFSET = 0.5

local ORIGIN_ERROR = 3
local HIT_POS_ERROR = 1.5
local SPEED_ERROR = 1.75

local TDSPlayer = {}
TDSPlayer.__index = TDSPlayer

function TDSPlayer.new(player)
    local self = {
        player = player,
        items = {},

        character = nil,
        alive = false,

        curItem = nil,

        fireStates = {},

        connections = {}
    }
    setmetatable(self, TDSPlayer)

    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(character)
    end))
    table.insert(self.connections, self.player.CharacterRemoving:Connect(function()
        self:CharacterRemoving()
    end))

    table.insert(self.connections, self.player.CharacterAppearanceLoaded:Connect(function(character)
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Accessory") then
                local part = child:FindFirstChildWhichIsA("BasePart")
                if part then
                    part.CanQuery = false
                    part.CanTouch = false
                    part.CollisionGroup = "NoCollide"
                end
            end
        end
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
end

function TDSPlayer:CharacterAdded(character)
    self.character = character
    self.character.PrimaryPart = self.character:WaitForChild("HumanoidRootPart")
    self.character.PrimaryPart.CanQuery = false
    self.character.PrimaryPart.CanTouch = false

    for _, part in ipairs(self.character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "Player"
        end
    end

    self.character:WaitForChild("Humanoid").BreakJointsOnDeath = false
    self.character.Humanoid.Died:Connect(function()
        self:Died()
    end)
    self.alive = true

    self.character.Humanoid.MaxHealth = MAX_HEALTH
    self.character.Humanoid.Health = MAX_HEALTH

    local shield = Instance.new("NumberValue")
    shield.Name = "Shield"
    shield.Parent = self.character.Humanoid

    local attach = Instance.new("Motor6D")
    attach.Name = "Attach"
    attach.Part0 = self.character:WaitForChild("Torso")
    attach.Parent = self.character.Torso

    local items = Instance.new("Folder")
    items.Name = "Items"
    items.Parent = self.character

    local projectileSpawn = Instance.new("Attachment")
    projectileSpawn.Name = "ProjectileSpawn"
    projectileSpawn.Position = Vector3.new(0, PROJECTILE_OFFSET, 0)
    projectileSpawn.Parent = self.character.PrimaryPart

    HitboxHandler:AddCharacter(self.character)
end
function TDSPlayer:CharacterRemoving()
    if self.alive then
        self:Died()
    end

    self.character = nil
end

local function Sunflower(n)
    local phi = (math.sqrt(5)+1) / 2

    local points = {}
    for k = 1, n do
        local r = math.sqrt(k-0.5) / math.sqrt(n-0.5)
        local theta = (2*math.pi*k) / (phi*phi)
        table.insert(points, Vector3.new(r*math.cos(theta), 0, r*math.sin(theta)))
    end
    return points
end
function TDSPlayer:Died()
    self.alive = false

    HitboxHandler:RemoveCharacter(self.character)

    if next(self.items) then
        local origin = self.character.PrimaryPart.Position
        local radius = math.sqrt(#self.items - 1) * ITEM_RADIUS * 2
        for _, point in ipairs(Sunflower(#self.items)) do
            local offset = point * radius

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {workspace.Baseplate}
            raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

            local target = origin + offset
            local raycastResult = workspace:Raycast(target, Vector3.new(0, -1000, 0), raycastParams)
            if raycastResult then
                target = raycastResult.Position
            end

            self:Drop(self.items[1], origin, target)
        end
    end

    -- REMOVE LATER: Respawn
    spawn(function()
        wait(5)
        self.player:LoadCharacter()
    end)
end

function TDSPlayer:Pickup(item)
    table.insert(self.items, item)

    item.Holster.Part1 = self.character.Torso
    item.Parent = self.character.Items

    CharacterRemotes.Add:FireClient(self.player, item)
end
function TDSPlayer:Drop(item, origin, target)
    local itemValue = Items:FindFirstChild(item.Name, true)
    if itemValue then
        local drop = script.Item:Clone()
        drop.Name = item.Name
        drop.Item.Value = itemValue
        drop:SetPrimaryPartCFrame(CFrame.new(origin) * CFrame.fromEulerAnglesXYZ(0, math.rad(90), math.rad(90)))

        for _, motor6D in ipairs(item.Motor6Ds:GetChildren()) do
            motor6D.Part0 = drop.PrimaryPart
        end
        item.Motor6Ds.Parent = drop
        item.Mesh.Parent = drop

        drop.Collider.Attachment.ParticleEmitter.Color = ColorSequence.new(item.Effects.Rarity.Value)

        drop.Parent = workspace.Drops

        drop.AlignPosition.Position = target
        Debris:AddItem(drop.AlignPosition, 2)
    end

    for index, value in ipairs(self.items) do
        if value == item then
            table.remove(self.items, index)
            break
        end
    end

    item:Destroy()
end

function TDSPlayer:Remotes()
    table.insert(self.connections, CharacterRemotes.Unequip.OnServerEvent:Connect(function(player)
        if player == self.player then
            if self.curItem and self.character then
                self.curItem.Holster.Enabled = true
                self.character.Torso.Attach.Part1 = nil
                self.curItem = nil
            end
        end
    end))
    table.insert(self.connections, CharacterRemotes.Equip.OnServerEvent:Connect(function(player, item)
        if player == self.player then
            if self.character and self.alive then
                if item and item.Parent == self.character.Items then
                    self.curItem = item
                    self.character.Torso.Attach.Part1 = self.curItem.PrimaryPart
                    self.curItem.Holster.Enabled = false
                end
            end
        end
    end))

    table.insert(self.connections, CharacterRemotes.Pickup.OnServerEvent:Connect(function(player, item)
        if player == self.player then
            if self.character and self.alive then
                local itemValue = item:FindFirstChild("Item")
                if item and itemValue then
                    if (item.PrimaryPart.Position - self.character.PrimaryPart.Position).Magnitude <= MAX_PICKUP_DISTANCE then
                        if itemValue.Value and #self.items < MAX_ITEMS then
                            self:Pickup(itemValue.Value:Clone())
                            item:Destroy()
                        end
                    end
                end
            end
        end
    end))
    table.insert(self.connections, CharacterRemotes.Drop.OnServerEvent:Connect(function(player, item)
        if player == self.player then
            if self.character and self.alive then
                if item then
                    local bool = false
                    for _, value in ipairs(self.items) do
                        if value == item then
                            bool = true
                        end
                    end
                    if bool then
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {workspace.Baseplate}
                        raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

                        local origin = self.character.PrimaryPart.Position
                        local target = origin
                        local raycastResult = workspace:Raycast(target, Vector3.new(0, -1000, 0), raycastParams)
                        if raycastResult then
                            target = raycastResult.Position
                        end

                        self:Drop(item, origin, target)
                    end
                end
            end
        end
    end))

    table.insert(self.connections, CharacterRemotes.Fire.OnServerEvent:Connect(function(player, origin, direction, fireID)
        if player == self.player then
            if self.character and self.alive then
                local pastPos = self.character.PrimaryPart.ProjectileSpawn.WorldPosition
                Debug.Vector(origin, pastPos, Color3.new(0, 0, 1))
                if (origin - pastPos).Magnitude <= ORIGIN_ERROR then
                    self.fireStates[fireID] = FireState.new(
                        origin,
                        direction.Unit * self.curItem.Settings.Distance.Value,
                        self.curItem.Settings.Speed.Value,
                        self.curItem.Settings.Damage.Value
                    )

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= self.player then
                            ControllerRemotes.ReplicateFire:FireClient(
                                player,
                                self.character,
                                direction.Unit * self.curItem.Settings.Distance.Value,
                                self.curItem.Settings.Distance.Value,
                                self.curItem.Effects.Projectile.Value
                            )
                        end
                    end
                end
            end
        end
    end))
    table.insert(self.connections, CharacterRemotes.Hit.OnServerEvent:Connect(function(player, hit, hitCFrame, fireID)
        if player == self.player then
            if hit and hit.Parent:FindFirstChildWhichIsA("Humanoid") then
                local fireState = self.fireStates[fireID]
                local hitboxState = HitboxHandler:GetHitboxState(hit.Parent, PingTimes[player])
                if fireState and hitboxState and hitboxState[hit.Name] then
                    local serverCFrame = hitboxState[hit.Name]
                    Debug.Vector(serverCFrame.Position, hitCFrame.Position, Color3.new(1, 0, 1))
                    if (hitCFrame.Position - serverCFrame.Position).Magnitude <= HIT_POS_ERROR then
                        local hitbox = HitboxCharacter:FindFirstChild(hit.Name):Clone()
                        hitbox.Transparency = Debug.enabled and 0 or 1
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
                            if distance / fireState.speed <= (tick() - fireState.serverTick) * SPEED_ERROR then
                                hit.Parent.Humanoid:TakeDamage(fireState.damage)
                            end
                        end

                        if Debug.enabled then
                            Debris:AddItem(hitbox, Debug.lifetime)
                        else
                            hitbox:Destroy()
                        end
                    end
                end
            end
        end
    end))
end

return TDSPlayer