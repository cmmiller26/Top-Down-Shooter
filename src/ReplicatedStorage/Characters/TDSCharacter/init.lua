local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projectile = require(ReplicatedStorage.Modules.Projectile)

local InteractPart = require(script.InteractPart)

local TDSCharacter = {}
TDSCharacter.__index = TDSCharacter

function TDSCharacter.new(gui, character)
    local self = {
        gui = gui,

        character = character,

        weapons = {},
        curWeapon = nil,

        animations = {},

        interactPart = nil,

        isFiring = false,
        canFire = false,
        toFire = false,

        fireID = 1,

        connections = {}
    }
    setmetatable(self, TDSCharacter)

    self:BindActions()

    self.interactPart = InteractPart.new(self.character, self.gui.Interact)

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
            self:Interact()
        end
    end
    ContextActionService:BindAction("TDSInteract", onInteract, false, Enum.KeyCode.F)
end
function TDSCharacter:UnbindActions()
    ContextActionService:UnbindAction("TDSFire")

    for i = 1, #EquipKeyCodes do
        ContextActionService:UnbindAction("TDSEquip" .. i)
    end
end

function TDSCharacter:Interact()
    local interact = self.interactPart:GetInteract()
    if interact then
        local module = interact:FindFirstChildWhichIsA("ModuleScript")
        if module then
            require(module):Interact()
        elseif interact:FindFirstChild("Item") then
            script.Remotes.Pickup:FireServer(interact)
        end
    end
end

function TDSCharacter:AddWeapon(weapon)
    table.insert(self.weapons, weapon)
    self.animations[weapon] = self.character.Humanoid.Animator:LoadAnimation(weapon.Idle)
end

function TDSCharacter:Unequip()
    if self.curWeapon then
        for _, animation in pairs(self.animations) do
            animation:Stop(0)
        end

        self.curWeapon.Holster.Enabled = true
        self.character.Torso.Attach.Part1 = nil

        script.Remotes.Unequip:FireServer()

        self.curWeapon = nil
        self.canFire = false
        self.toFire = false
    end
end
function TDSCharacter:Equip(slot)
    if not self.isFiring then
        local weapon = self.weapons[slot]
        if weapon and weapon ~= self.curWeapon then
            self:Unequip()

            self.curWeapon = weapon
            script.Remotes.Equip:FireServer(self.curWeapon)

            self.character.Torso.Attach.Part1 = self.curWeapon.PrimaryPart
            self.curWeapon.Holster.Enabled = false

            self.animations[self.curWeapon]:Play(0)

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

    if self.curWeapon and self.canFire and self.toFire then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {self.character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local function Fire()
            local fireID = self.fireID
            self.fireID += 1

            local origin = self.character.PrimaryPart.ProjectileSpawn.WorldPosition
            local direction = self.character.PrimaryPart.CFrame.LookVector
            local projectile = Projectile.new({
                origin = origin,
                velocity = direction * self.curWeapon.Settings.Speed.Value,
                distance = self.curWeapon.Settings.Distance.Value,
                raycastParams = raycastParams,
                meshPrefab = self.curWeapon.Effects.Projectile.Value
            })
            
            script.Remotes.Fire:FireServer(origin, direction, fireID, tick())

            projectile.Hit.Event:Connect(function(raycastResult)
                if raycastResult then
                    local hit = raycastResult.Instance
                    script.Remotes.Hit:FireServer(hit, hit.CFrame, fireID, tick())
                end
            end)

            wait(60/self.curWeapon.Settings.RPM.Value)
        end

        repeat
            self.canFire = false
            self.isFiring = true
    
            Fire()
    
            self.isFiring = false
            self.canFire = true
        until not self.toFire or not self.curWeapon.Settings.Auto.Value
    end
end

function TDSCharacter:Remotes()
    table.insert(self.connections, script.Remotes.AddWeapon.OnClientEvent:Connect(function(weapon)
        self:AddWeapon(weapon)
    end))
end

return TDSCharacter