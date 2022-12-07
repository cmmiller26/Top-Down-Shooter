local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
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
        items = {
            weapons = {}
        },

        character = nil,
        alive = false,

        curWeapon = nil,

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
            if child:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(child, "Player")
            elseif child:IsA("Accessory") then
                local part = child:FindFirstChildWhichIsA("BasePart")
                if part then
                    part.CanQuery = false
                    part.CanTouch = false
                    PhysicsService:SetPartCollisionGroup(part, "NoCollide")
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

    self.character:WaitForChild("Humanoid").BreakJointsOnDeath = false
    self.character.Humanoid.Died:Connect(function()
        self:Died()
    end)
    self.alive = true

    local attach = Instance.new("Motor6D")
    attach.Name = "Attach"
    attach.Part0 = self.character:WaitForChild("Torso")
    attach.Parent = self.character.Torso

    local projectileSpawn = Instance.new("Attachment")
    projectileSpawn.Name = "ProjectileSpawn"
    projectileSpawn.Position = Vector3.new(0, PROJECTILE_OFFSET, 0)
    projectileSpawn.Parent = self.character.PrimaryPart

    HitboxHandler:AddCharacter(self.character)

    wait(2)
    
    self:PickupItem(Items.Weapons.AK47:Clone())
    self:PickupItem(Items.Weapons.Deagle:Clone())
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

    local items = {}
    for name, tbl in pairs(self.items) do
        for _, value in ipairs(tbl) do
            table.insert(items, value)
        end
        self.items[name] = {}
    end

    if next(items) then
        local radius = math.sqrt(#items - 1) * ITEM_RADIUS
        for index, point in ipairs(Sunflower(#items)) do
            local offset = point * radius
            self:DropItem(items[index], self.character.PrimaryPart.Position + offset)
        end
    end

    -- REMOVE LATER: Respawn
    spawn(function()
        wait(5)
        self.player:LoadCharacter()
    end)
end

function TDSPlayer:PickupItem(item)
    if item:FindFirstChild("Weapon") then
        table.insert(self.items.weapons, item)

        item.Holster.Part1 = self.character.Torso
        item.Parent = self.character

        CharacterRemotes.AddWeapon:FireClient(self.player, item)
    end
end
function TDSPlayer:DropItem(item, position)
    local itemValue = Items:FindFirstChild(item.Name, true)
    if itemValue then
        local drop = script.Item:Clone()
        drop.Name = item.Name
        drop.Item.Value = itemValue
        drop:SetPrimaryPartCFrame(CFrame.new(position) * CFrame.Angles(0, math.pi/2, math.pi/2))

        for _, motor6D in ipairs(item.Motor6Ds:GetChildren()) do
            motor6D.Part0 = drop.PrimaryPart
        end
        item.Motor6Ds.Parent = drop
        item.Mesh.Parent = drop

        drop.Parent = workspace
    end

    item:Destroy()
end

function TDSPlayer:Remotes()
    table.insert(self.connections, CharacterRemotes.Unequip.OnServerEvent:Connect(function(player)
        if player == self.player then
            if self.curWeapon and self.character then
                self.curWeapon.Holster.Enabled = true
                self.character.Torso.Attach.Part1 = nil
                self.curWeapon = nil
            end
        end
    end))
    table.insert(self.connections, CharacterRemotes.Equip.OnServerEvent:Connect(function(player, weapon)
        if player == self.player then
            if self.character and self.alive then
                if weapon and weapon.Parent == self.character then
                    self.curWeapon = weapon
                    self.character.Torso.Attach.Part1 = self.curWeapon.PrimaryPart
                    self.curWeapon.Holster.Enabled = false
                end
            end
        end
    end))

    table.insert(self.connections, CharacterRemotes.Pickup.OnServerEvent:Connect(function(player, item)
        if player == self.player then
            if self.character and self.alive then
                if item and item:FindFirstChild("Item") then
                    if (item.PrimaryPart.Position - self.character.PrimaryPart.Position).Magnitude <= MAX_PICKUP_DISTANCE then
                        if item.Item.Value then
                            self:PickupItem(item.Item.Value:Clone())
                        end
                        item:Destroy()
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
                        direction.Unit * self.curWeapon.Settings.Distance.Value,
                        self.curWeapon.Settings.Speed.Value,
                        self.curWeapon.Settings.Damage.Value
                    )

                    for _, otherPlayer in ipairs(Players:GetPlayers()) do
                        if otherPlayer ~= self.player then
                            ControllerRemotes.ReplicateFire:FireClient(
                                otherPlayer,
                                self.character,
                                direction.Unit * self.curWeapon.Settings.Distance.Value,
                                self.curWeapon.Settings.Distance.Value,
                                self.curWeapon.Effects.Projectile.Value
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