local TweenService = game:GetService("TweenService")

local Door = {}
Door.__index = Door

function Door.new(model)
    local self = {
        model = model,

        interact = model.Interact,
        mesh = model.Mesh,

        Settings = model.Settings,

        open = model.Open,

        connection = nil
    }

    setmetatable(self, Door)

    self.connection = self.model.Remote.OnServerEvent:Connect(function(player)
        if player.Character then
            local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                self:Interact(player.Character.PrimaryPart.Position)
            end
        end
    end)

    return self
end
function Door:Destroy()
    self.connection:Destroy()

    self:Close()
end

function Door:Interact(pos)
    local goal = self.Settings.CloseOrientation.Value
    if not self.open.Value then
        goal = self.Settings.OpenOrientation.Value
        if pos.Z > self.interact.Position.Z then
            goal *= -1
        end
    end

    local tweenInfo = TweenInfo.new(self.Settings.Time.Value, Enum.EasingStyle.Sine)
    local tween = TweenService:Create(self.mesh.PrimaryPart, tweenInfo, {Orientation = goal})
    tween:Play()
    
    self.interact.Parent = nil
    self.mesh.Collider.CanCollide = false
    
    tween.Completed:Wait()
    
    self.mesh.Collider.CanCollide = true
    self.interact.Parent = self.model
    
    self.open.Value = not self.open.Value
end

return Door