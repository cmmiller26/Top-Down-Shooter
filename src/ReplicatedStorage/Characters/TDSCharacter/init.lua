local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projectile = require(ReplicatedStorage.Modules.Projectile)

local InteractPart = require(script.InteractPart)

local MAX_ITEMS = 5

local TDSCharacter = {}
TDSCharacter.__index = TDSCharacter

function TDSCharacter.new(gui, character)
    local self = {
        gui = gui,

        character = character,

        items = {},
        curItem = nil,

        animations = {},

        interactPart = nil,

        isFiring = false,
        canFire = false,
        toFire = false,

        fireID = 1,

        connections = {}
    }
    setmetatable(self, TDSCharacter)

    for i = 1, MAX_ITEMS do
        self.items[i] = false
    end

    self:BindActions()

    self.interactPart = InteractPart.new(self.character, self.gui)

    self:Remotes()

    return self
end
function TDSCharacter:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    self.interactPart:Destroy()
    self:UnbindActions()

    self:Unequip()
end

local EquipKeyCodes = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five
}
function TDSCharacter:BindActions()
    for i = 1, #EquipKeyCodes do
        local function onEquip(_, inputState)
            if inputState == Enum.UserInputState.Begin then
                self:Equip(i)
            end
        end
        ContextActionService:BindAction("TDSEquip" .. i, onEquip, false, EquipKeyCodes[i])
    end

    local function onFire(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self:Fire(true)
        elseif inputState == Enum.UserInputState.End then
            self:Fire(false)
        end
    end
    ContextActionService:BindAction("TDSFire", onFire, false, Enum.UserInputType.MouseButton1)

    local function onInteract(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self:Interact(true)
        elseif inputState == Enum.UserInputState.End then
            self:Interact(false)
        end
    end
    ContextActionService:BindAction("TDSInteract", onInteract, false, Enum.KeyCode.F)

    local function onDrop(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self:Drop()
        end
    end
    ContextActionService:BindAction("TDSDrop", onDrop, false, Enum.KeyCode.Q)
end
function TDSCharacter:UnbindActions()
    ContextActionService:UnbindAction("TDSFire")

    for i = 1, #EquipKeyCodes do
        ContextActionService:UnbindAction("TDSEquip" .. i)
    end
end

function TDSCharacter:Interact(bool)
    self.gui:Interact(self.interactPart:GetInteract(), bool)
end

function TDSCharacter:Add(item)
    for index, value in pairs(self.items) do
        if not value then
            self.items[index] = item
            self.gui:Add(item, index)
            break
        end
    end

    self.animations[item] = self.character.Humanoid.Animator:LoadAnimation(item.Idle)
end
function TDSCharacter:Drop()
    if self.curItem and not self.isFiring then
        local item = self.curItem
        self:Unequip()

        script.Remotes.Drop:FireServer(item)

        for index, value in pairs(self.items) do
            if value == item then
                self.gui:Remove(index)
                self.items[index] = false
                break
            end
        end
    end
end

function TDSCharacter:Unequip()
    if self.curItem then
        self.toFire = false
        self.canFire = false

        self.gui:Unequip()

        for _, animation in pairs(self.animations) do
            animation:Stop(0)
        end

        self.curItem.Holster.Enabled = true
        self.character.Torso.Attach.Part1 = nil

        script.Remotes.Unequip:FireServer()
        self.curItem = nil
    end
end
function TDSCharacter:Equip(slot)
    if not self.isFiring then
        local item = self.items[slot]
        if item and item ~= self.curItem then
            self:Unequip()

            self.curItem = item
            script.Remotes.Equip:FireServer(self.curItem)

            self.character.Torso.Attach.Part1 = self.curItem.PrimaryPart
            self.curItem.Holster.Enabled = false

            self.animations[self.curItem]:Play(0)

            for index, item in ipairs(self.items) do
                if item == self.curItem then
                    self.gui:Equip(index, item)
                    break
                end
            end

            self.canFire = true
        else
            self:Unequip()
        end
    end
end

function TDSCharacter:Fire(toFire)
    if not (self.toFire and toFire) then
        self.toFire = toFire
    end

    if self.curItem and self.canFire and self.toFire then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {self.character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local function Fire()
            local fireID = self.fireID
            self.fireID += 1

            self.curItem.PrimaryPart.Barrel.Flash:Emit(1)

            local origin = self.character.PrimaryPart.ProjectileSpawn.WorldPosition
            local direction = self.character.PrimaryPart.CFrame.LookVector
            local projectile = Projectile.new({
                origin = origin,
                velocity = direction * self.curItem.Settings.Speed.Value,
                distance = self.curItem.Settings.Distance.Value,
                raycastParams = raycastParams,
                meshPrefab = self.curItem.Effects.Projectile.Value
            })

            script.Remotes.Fire:FireServer(origin, direction, fireID, tick())

            projectile.Hit.Event:Connect(function(raycastResult)
                if raycastResult then
                    local hit = raycastResult.Instance
                    script.Remotes.Hit:FireServer(hit, hit.CFrame, fireID, tick())
                end
            end)

            wait(60/self.curItem.Settings.RPM.Value)
        end

        repeat
            self.canFire = false
            self.isFiring = true

            Fire()

            self.isFiring = false
            self.canFire = true
        until not self.curItem or not self.toFire or not self.curItem.Settings.Auto.Value
    end
end

function TDSCharacter:Remotes()
    table.insert(self.connections, script.Remotes.Add.OnClientEvent:Connect(function(item)
        self:Add(item)
    end))

    table.insert(self.connections, script.Remotes.Scope.OnClientEvent:Connect(function(value)
        self.gui:Scope(value)
    end))
end

return TDSCharacter