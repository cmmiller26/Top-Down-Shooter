local TweenService = game:GetService("TweenService")

local MAX_HEALTH = 100
local MAX_SHIELD = 100

local MAX_ITEMS = 5

local BAR_SPEED = 10

local DEFAULT_BACKGROUND_COLOR = Color3.fromRGB(50, 50, 50)

local SLOT_DEFAULT_SIZE = UDim2.fromScale(1, 1)
local SLOT_EQUIP_SIZE = UDim2.fromScale(1.25, 1.25)

local TDSGui = {}
TDSGui.__index = TDSGui

function TDSGui.new(player, camera, character)
    local self = {
        camera = camera,

        gui = nil,

        character = character,

        curSlot = nil,
        full = nil,

        bar = nil
    }

    setmetatable(self, TDSGui)

    self.gui = script.ScreenGui:Clone()
    self.gui.Parent = player.PlayerGui

    self.character.Humanoid.HealthChanged:Connect(function(health)
        self:Stat(health, "Health", MAX_HEALTH)
    end)
    self.character.Humanoid.Shield.Changed:Connect(function(shield)
        self:Stat(shield, "Shield", MAX_SHIELD)
    end)

    self:Scope(1)

    return self
end
function TDSGui:Destroy()
    self.gui:Destroy()
end

function TDSGui:Died()
    for _, frame in ipairs(self.gui:GetChildren()) do
        frame.Visible = false
    end
end

function TDSGui:Stat(value, name, maxValue)
    local frame = self.gui.Stats:FindFirstChild(name)
    if frame then  
        value = math.max(0, value)

        local text = frame.Label.Text
        local prevValue = string.split(string.split(text, ">")[2], "<")[1]
        frame.Label.Text = string.gsub(text, prevValue, math.round(value), 1)

        local tweenInfo = TweenInfo.new(math.sqrt(math.abs(prevValue - value)) / BAR_SPEED, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame.Bar, tweenInfo, {
            Size = UDim2.fromScale(value / maxValue, 1)
        })
        tween:Play()
    end
end

local VALID = {
    ["RootPart"] = true,
    ["Mesh"] = true,
    ["Motor6Ds"] = true
}
function TDSGui:Add(item, slot)
    local frame = self.gui.Items:FindFirstChild("Slot" .. slot)
    if frame then
        frame.BackgroundColor3 = item.Effects.Color.Value
        frame.Number.Visible = true

        local mesh = item:Clone()
        for _, child in ipairs(mesh:GetChildren()) do
            if not VALID[child.Name] then
                child:Destroy()
            end
        end
        mesh:SetPrimaryPartCFrame(item.Effects.Image.Value)
        mesh.Parent = frame.Image
    end
end
function TDSGui:Remove(slot)
    local frame = self.gui.Items:FindFirstChild("Slot" .. slot)
    if frame then
        for _, child in ipairs(frame.Image:GetChildren()) do
            child:Destroy()
        end

        frame.Number.Visible = false
        frame.BackgroundColor3 = DEFAULT_BACKGROUND_COLOR
    end
end

function TDSGui:Equip(slot, item)
    self:Unequip()

    local frame = self.gui.Items:FindFirstChild("Slot" .. slot)
    if frame then
        self.curSlot = frame
        self.curSlot.Size = SLOT_EQUIP_SIZE

        self.curSlot.Label.Text = item.Name

        self.gui.Items.Ammo.Visible = true
    end
end
function TDSGui:Unequip()
    if self.curSlot then
        self.gui.Items.Ammo.Visible = false
        self.curSlot.Label.Text = ""
        self.curSlot.Size = SLOT_DEFAULT_SIZE
    end
end

local function GetLabel(interact)
    if interact.Type.Value == "Item" then
        return "Pickup " .. interact.Name
    elseif interact.Type.Value == "Door" then
        return interact.Open.Value and "Close Door" or "Open Door"
    end
end
function TDSGui:Prompt(visible, interact)
    local frame = self.gui.Interact
    frame.Visible = visible
    frame.Label.Text = visible and GetLabel(interact) or ""
end

function TDSGui:Interact(interact, bool)
    if interact and bool then
        if interact.Type.Value == "Item" then
            if #self.character.Items:GetChildren() < MAX_ITEMS then
                script.Remotes.Pickup:FireServer(interact)
            elseif not self.full then
                self.full = self.gui.Interact.Full:Clone()
                self.full.Parent = self.gui.Interact
                self.full.Visible = true
        
                wait (0.35)
        
                local tween = TweenService:Create(self.full, TweenInfo.new(0.15), {
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                })
                tween:Play()
                tween.Completed:Wait()
        
                self.full:Destroy()
                self.full = nil
            end
        else
            interact.Begin:FireServer()

            self.bar = self.gui.Interact.Label.Bar:Clone()
            self.bar.Parent = self.gui.Interact.Label
            self.bar.Visible = true

            local tween = TweenService:Create(self.bar, TweenInfo.new(interact.Time.Value), {
                Size = UDim2.fromScale(1, self.bar.Size.Y.Scale)
            })
            tween:Play()
            tween.Completed:Wait()

            if tween.Instance == self.bar then
                self.bar:Destroy()
                self.bar = nil

                interact.End:FireServer()
            end
        end
    end
    
    if not bool and self.bar then
        self.bar:Destroy()
        self.bar = nil
    end
end

function TDSGui:Scope(value)
    local button = self.gui.Scopes:FindFirstChild(value)
    if button then
        button.Visible = true

        local function Activated()
            for _, child in ipairs(self.gui.Scopes:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Size = SLOT_DEFAULT_SIZE
                end
            end

            self.camera:Zoom(value)

            button.Size = SLOT_EQUIP_SIZE
        end
        button.Activated:Connect(Activated)
        
        Activated()
    end
end

return TDSGui