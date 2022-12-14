local TweenService = game:GetService("TweenService")

local SLOT_DEFAULT_SIZE = UDim2.fromScale(1, 1)
local SLOT_EQUIP_SIZE = UDim2.fromScale(1.15, 1.15)

local TDSGui = {}
TDSGui.__index = TDSGui

function TDSGui.new(player)
    local self = {
        player = player,

        gui = nil,

        curSlot = nil
    }

    self.gui = script.ScreenGui:Clone()
    self.gui.Parent = self.player.PlayerGui

    setmetatable(self, TDSGui)

    return self
end
function TDSGui:Destroy()
    self.gui:Destroy()
end

function TDSGui:Equip(slot, item)
    self:Unequip()

    local frame = self.gui.Items:FindFirstChild("Slot" .. slot)
    if frame then
        self.curSlot = frame
        self.curSlot.Size = SLOT_EQUIP_SIZE

        self.curSlot.Label.Text = item.Name
    end
end
function TDSGui:Unequip()
    if self.curSlot then
        self.curSlot.Label.Text = ""
        self.curSlot.Size = SLOT_DEFAULT_SIZE
    end
end

function TDSGui:Interact(visible, message)
    self.gui.Interact.Visible = visible
    self.gui.Interact.Label.Text = visible and message or ""
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