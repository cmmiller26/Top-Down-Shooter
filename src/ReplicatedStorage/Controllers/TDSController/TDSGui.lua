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

        curSlot = nil
    }

    self.gui = script.ScreenGui:Clone()
    self.gui.Parent = player.PlayerGui

    setmetatable(self, TDSGui)

    return self
end
function TDSGui:Destroy()
    self.gui:Destroy()
end

function TDSGui:Health(health)
    health = math.max(0, health)
    local frame = self.gui.Stats.Health

    local text = frame.Label.Text
    local prevHealth = string.split(string.split(text, ">")[2], "<")[1]
    frame.Label.Text = string.gsub(text, prevHealth, health, 1)

    local tweenInfo = TweenInfo.new(math.sqrt(math.abs(prevHealth - health)) / BAR_SPEED, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame.Bar, tweenInfo, {
        Size = UDim2.fromScale(health / MAX_HEALTH, 1)
    })
    tween:Play()
end
function TDSGui:Shield(shield)
    shield = math.max(0, shield)
    local frame = self.gui.Stats.Shield

    local text = frame.Label.Text
    local prevShield = string.split(string.split(text, ">")[2], "<")[1]
    frame.Label.Text = string.gsub(text, prevShield, shield, 1)

    local tweenInfo = TweenInfo.new(math.sqrt(math.abs(prevShield - shield)) / BAR_SPEED, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame.Bar, tweenInfo, {
        Size = UDim2.fromScale(shield / MAX_SHIELD, 1)
    })
    tween:Play()
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

function TDSGui:Interact(visible, message)
    local frame = self.gui.Interact
    frame.Visible = visible
    frame.Label.Text = visible and message or ""
end

function TDSGui:Full()
    if not self.gui.Interact:FindFirstChild("Full") then
        local label = self.gui.Interact.FullPrefab:Clone()
        label.Name = "Full"
        label.Parent = self.gui.Interact
        label.Visible = true

        wait(0.35)

        local tween = TweenService:Create(label, TweenInfo.new(0.15), {
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()

        label:Destroy()
    end
end

return TDSGui