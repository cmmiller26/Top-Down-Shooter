local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projectile = require(ReplicatedStorage.Modules.Projectile)

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
        curItem = nil,

        isFiring = false,
        canFire = false,
        toFire = false,

        fireID = 1
    }

    setmetatable(self, TDSCharacter)

    self:BindActions()
    self:CreateInteractPart()

    return self
end
function TDSCharacter:Destroy()
    self.interactPart:Destroy()
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

function TDSCharacter:CreateInteractPart()
    self.interactPart = script.InteractPart:Clone()
    self.interactPart.Weld.Part0 = self.character.HumanoidRootPart
    self.interactPart.Parent = self.character

    self.interactPart.Touched:Connect(function(otherPart)
        if otherPart.Name == "Collider" then
            local item = otherPart.Parent
            if item:FindFirstChild("Item") then
                if item ~= self.curItem then
                    self.curItem = item

                    self.gui.Pickup.Label.Text = "Pickup " .. self.curItem.Name
                    self.gui.Pickup.Visible = true
                end
            end
        end
    end)

    self.interactPart.TouchEnded:Connect(function(otherPart)
        if otherPart.Name == "Collider" then
            local item = otherPart.Parent
            if item and item:FindFirstChild("Item") then
                if item == self.curItem then
                    self.gui.Pickup.Visible = false
                    self.gui.Pickup.Label.Text = ""

                    self.curItem = nil
                end
            end
        end
    end)
end
function TDSCharacter:Interact()
    if self.curItem then
        script.Remotes.Pickup:FireServer(self.curItem)

        self.gui.Pickup.Visible = false
        self.gui.Pickup.Label.Text = ""

        self.curItem:Destroy()
        self.curItem = nil
    end
end

function TDSCharacter:AddWeapon(weapon)
    self.animations[weapon] = self.character.Humanoid.Animator:LoadAnimation(weapon.Idle)
end
function TDSCharacter:RemoveWeapon(weapon)
    self.animations[weapon] = nil
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
        until not self.toFire
    end
end

return TDSCharacter