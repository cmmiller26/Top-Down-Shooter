local TweenService = game:GetService("TweenService")

local MAX_HEALTH = 100
local MAX_SHIELD = 100

local BAR_SPEED = 10

local SLOT_DEFAULT_SIZE = UDim2.fromScale(1, 1)
local SLOT_EQUIP_SIZE = UDim2.fromScale(1.15, 1.15)

local TDSGui = {}
TDSGui.__index = TDSGui

function TDSGui.new(player)
    local self = {
        gui = nil,

        character = nil,

        curSlot = nil,
        full = nil,

        connections = {}
    }

    setmetatable(self, TDSGui)

    self.gui = script.ScreenGui:Clone()
    self.gui.Parent = player.PlayerGui

    return self
end
function TDSGui:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    self.gui:Destroy()
end

function TDSGui:CharacterAdded(character)
    self.character = character

    table.insert(self.connections, self.character.Humanoid.HealthChanged:Connect(function(health)
        self:Stat(health, "Health", MAX_HEALTH)
    end))
    table.insert(self.connections, self.character.Humanoid.Shield.Changed:Connect(function(shield)
        self:Stat(shield, "Shield", MAX_SHIELD)
    end))
end
function TDSGui:CharacterRemoving()
    self.character = nil
end

function TDSGui:Died()
    self.gui.Interact.Visible = false
    self.gui.Interact.Label.Text = ""
end

function TDSGui:Stat(value, name, maxValue)
    local frame = self.gui.Stats:FindFirstChild(name)
    if frame then  
        value = math.max(0, value)

        local text = frame.Label.Text
        local prevValue = string.split(string.split(text, ">")[2], "<")[1]
        frame.Label.Text = string.gsub(text, prevValue, value, 1)
        print(value, prevValue, maxValue)

        local tweenInfo = TweenInfo.new(math.sqrt(math.abs(prevValue - value)) / BAR_SPEED, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame.Bar, tweenInfo, {
            Size = UDim2.fromScale(value / maxValue, 1)
        })
        tween:Play()
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

function TDSGui:Interact()
    if self.full then
        self.full = self.gui.Interact.Full:Clone()
        self.full.Name = "Full"
        self.full.Parent = self.gui.Interact
        self.full.Visible = true

        wait (0.35)

        local tween = TweenService:Create(self.frame, TweenInfo.new(0.15), {
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()

        self.frame:Destroy()
    end
end

return TDSGui