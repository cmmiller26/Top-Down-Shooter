local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Debug = require(ReplicatedStorage.Debug)

local Projectile = {}

function Projectile.new(args)
    local self = {
        origin = args.origin,
        position = args.origin,

        velocity = args.velocity,

        distance = args.distance,

        raycastParams = args.raycastParams,

        mesh = nil,

        Hit = Instance.new("BindableEvent"),

        connection = nil,
    }
    
    self.mesh = args.meshPrefab:Clone()
    self.mesh.Parent = workspace.Bullets
    print(self.mesh, self.mesh.Parent)

    table.insert(self.connections, RunService.Heartbeat:Connect(function(deltaTime)
        if (self.position - self.origin).Magnitude < self.distance then
            local direction = self.velocity * deltaTime

            local raycastResult = workspace:Raycast(self.position, direction, self.raycastParams)
            if raycastResult then
                Debug.Point(raycastResult.Position, Color3.new(1, 0, 0))

                self.Hit:Fire(raycastResult)

                self:Destroy()
                return
            end

            Debug.Point(self.position, Color3.new(0, 1, 0))

            self.position += direction
            self.mesh:SetPrimaryPartCFrame(CFrame.new(self.position, self.position + direction))
        else
            self:Destroy()
        end
    end)

    function self:Destroy()
        self.connection:Disconnect()

        self.mesh:Destroy()
    end

    return self
end

return Projectile