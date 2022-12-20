local TweenService = game:GetService("TweenService")

local TIME_ERROR = 0.1

local Door = {}
Door.__index = Door

function Door.new(model)
    local self = {
        model = model,

        interact = model.Interact,
        mesh = model.Mesh,

        Settings = model.Settings,

        open = model.Open,
        interactTime = model.Time,

        interactions = {},

        connections = {}
    }

    setmetatable(self, Door)

    table.insert(self.connections, self.model.Begin.OnServerEvent:Connect(function(player)
        if player.Character then
            local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                self.interactions[player] = {
                    serverTick = tick(),
                    position = player.Character.PrimaryPart.Position
                }
            end
        end
    end))
    table.insert(self.connections, self.model.End.OnServerEvent:Connect(function(player)
        local interaction = self.interactions[player]
        if interaction then
            if tick() - interaction.serverTick >= self.interactTime.Value - TIME_ERROR then
                self:Interact(interaction.position)
            end
        end
    end))

    return self
end
function Door:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    if self.open.Value then
        self:Interact()
    end
end

function Door:Interact(pos)
    local goal = self.Settings.CloseOrientation.Value
    if not self.open.Value then
        goal = self.Settings.OpenOrientation.Value
        if pos.Z > self.interact.Position.Z then
            goal *= -1
        end
    end

    local tweenInfo = TweenInfo.new(self.Settings.TweenTime.Value, Enum.EasingStyle.Sine)
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