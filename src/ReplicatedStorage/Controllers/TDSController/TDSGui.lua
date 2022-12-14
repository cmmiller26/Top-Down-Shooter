local TweenService = game:GetService("TweenService")

local TDSGui = {}
TDSGui.__index = TDSGui

function TDSGui.new(player)
    local self = {
        player = player,

        gui = nil
    }

    self.gui = script.ScreenGui:Clone()
    self.gui.Parent = self.player.PlayerGui

    setmetatable(self, TDSGui)

    return self
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