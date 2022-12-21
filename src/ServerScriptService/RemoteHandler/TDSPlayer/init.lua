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
local GuiRemotes = ReplicatedStorage.Controllers.TDSController.TDSGui.Remotes
local CharacterRemotes = ReplicatedStorage.Characters.TDSCharacter.Remotes

local HitboxCharacter = ReplicatedStorage.HitboxCharacter

local MAX_HEALTH = 100
local MAX_SHIELD = 100

local MAX_ITEMS = 5

local MAX_PICKUP_DISTANCE = 4
local ITEM_RADIUS = 1

local DROP_TIME = 2

local PROJECTILE_OFFSET = 0.5

local ORIGIN_ERROR = 3
local HIT_POS_ERROR = 1.5
local SPEED_ERROR = 0.25

local function TableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

local TDSPlayer = {}
TDSPlayer.__index = TDSPlayer

function TDSPlayer.new(player)
    local self = {
        player = player,
        items = {},
        scopes = {},

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

    local drops = TableConcat(self.items, self.scopes)
    if next(drops) then
        local origin = self.character.PrimaryPart.Position
        local radius = math.sqrt(#drops - 1) * ITEM_RADIUS * 2
        for index, point in ipairs(Sunflower(#drops)) do
            local drop = drops[index]
            drops[index] = true

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {workspace.Baseplate}
            raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

            local target = origin + point * radius
            local raycastResult = workspace:Raycast(target, Vector3.new(0, -1000, 0), raycastParams)
            if raycastResult then
                target = raycastResult.Position
            end

            self:Drop(drop, origin, target)
        end
    end

    self.items = {}
    self.scopes = {}

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
    if type(item) == "number" then
        local drop = script.Scope:Clone()
        drop.Name = item .. "x Scope"
        drop.Scope.Value = item
        drop:SetPrimaryPartCFrame(CFrame.new(origin) * CFrame.fromEulerAnglesXYZ(0, math.rad(90), math.rad(90)))

        drop.Mesh.Part.SurfaceGui.Label.Text = item .. "x"

        drop.Parent = workspace.Drops

        drop.AlignPosition.Position = target
        Debris:AddItem(drop.AlignPosition, DROP_TIME)

        for index, value in ipairs(self.scopes) do
            if value == item then
                table.remove(self.scopes, index)
                break
            end
        end
    else
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

            drop.Collider.Attachment.ParticleEmitter.Color = ColorSequence.new(item.Effects.Color.Value)

            drop.Parent = workspace.Drops

            drop.AlignPosition.Position = target
            Debris:AddItem(drop.AlignPosition, DROP_TIME)
        end

        for index, value in ipairs(self.items) do
            if value == item then
                table.remove(self.items, index)
                break
            end
        end
        item:Destroy()
    end
end

function TDSPlayer:Scope(value)
    table.insert(self.scopes, value)
    CharacterRemotes.Scope:FireClient(self.player, value)
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

    table.insert(self.connections, GuiRemotes.Pickup.OnServerEvent:Connect(function(player, item)
        if player == self.player then
            if self.character and self.alive then
                if item and (item.PrimaryPart.Position - self.character.PrimaryPart.Position).Magnitude <= MAX_PICKUP_DISTANCE then
                    local itemValue = item:FindFirstChild("Item")
                    local scopeValue = item:FindFirstChild("Scope")

                    if itemValue and itemValue.Value and #self.items < MAX_ITEMS then
                        self:Pickup(itemValue.Value:Clone())
                    elseif scopeValue then
                        self:Scope(scopeValue.Value)
                    else
                        return
                    end

                    item:Destroy()
                end
            end
        end
    end))
    table.insert(self.connections, CharacterRemotes.Drop.OnServerEvent:Connect(function(player, item)
        if player == self.player then
            if self.character and self.alive then
                if item and item.Parent == self.character.Items then
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
    end))

    table.insert(self.connections, CharacterRemotes.Fire.OnServerEvent:Connect(function(player, origin, direction, fireID)
        if player == self.player then
            if self.character and self.alive then
                if self.curItem and self.curItem.Parent == self.character.Items then
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
                                    self.curItem,
                                    direction.Unit * self.curItem.Settings.Distance.Value
                                )
                            end
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
                            local predictTime = distance / fireState.speed
                            local realTime = (tick() - fireState.serverTick)
                            if math.abs(realTime - predictTime) <= SPEED_ERROR then
                                local humanoid = hit.Parent.Humanoid
                                local shield = humanoid:FindFirstChild("Shield")
                                if shield and shield.Value > 0 then
                                    shield.Value = math.max(0, shield.Value - fireState.damage)
                                else
                                    humanoid:TakeDamage(fireState.damage)
                                end
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