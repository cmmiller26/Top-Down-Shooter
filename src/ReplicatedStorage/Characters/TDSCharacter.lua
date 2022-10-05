local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projectile = require(ReplicatedStorage.Projectile)

local TDSCharacter = {}
TDSCharacter.__index = TDSCharacter

function TDSCharacter.new(weapons, character)
    local self = {
        character = character,

        weapons = weapons,
        curWeapon = nil,

        isFiring = false,
        canFire = false,
        toFire = false,

        fireID = 1,

        animations = {}
    }

    setmetatable(self, TDSCharacter)

    for _, weapon in ipairs(self.weapons) do
        self.animations[weapon] = self.character.Humanoid.Animator:LoadAnimation(weapon.Idle)
    end

    self:BindActions()

    return self
end
function TDSCharacter:Destroy()
    self:UnbindActions()
    self:Unequip()
end

local EquipKeyCodes = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three
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
end
function TDSCharacter:UnbindActions()
    ContextActionService:UnbindAction("TDSFire")

    for i = 1, #EquipKeyCodes do
        ContextActionService:UnbindAction("TDSEquip" .. i)
    end
end

function TDSCharacter:Unequip()
    if self.curWeapon then
        for _, animation in pairs(self.animations) do
            animation:Stop(0)
        end

        self.curWeapon.Holster.Enabled = true
        self.character.Torso.Attach.Part1 = nil

        script.Unequip:FireServer()

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
            script.Equip:FireServer(self.curWeapon)

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

            local rootCFrame = self.character.PrimaryPart.CFrame
            local origin = rootCFrame.Position
            local direction = rootCFrame.LookVector

            local projectile = Projectile.new({
                origin = origin,
                velocity = direction * self.curWeapon.Settings.Speed.Value,
                distance = self.curWeapon.Settings.Distance.Value,
                raycastParams = raycastParams,
                meshPrefab = self.curWeapon.Effects.Projectile.Value,
                meshPos = self.curWeapon.PrimaryPart.Barrel.WorldPosition
            })

            script.Fire:FireServer(origin, direction, fireID, tick())

            projectile.Hit.Event:Connect(function(raycastResult)
                if raycastResult then
                    script.Hit:FireServer(raycastResult.Instance, fireID, tick())
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
        until not self.toFire
    end
end

return TDSCharacter