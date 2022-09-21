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
        meshOffset = args.meshPos - args.origin,

        connections = {}
    }
    
    self.mesh = args.meshPrefab:Clone()
    self.mesh.Parent = workspace.Bullets

    table.insert(self.connections, RunService.Heartbeat:Connect(function(deltaTime)
        if (self.position - self.origin).Magnitude < self.distance then
            local direction = self.velocity * deltaTime

            local raycastResult = workspace:Raycast(self.position, direction, self.raycastParams)
            if raycastResult then
                Debug.Point(raycastResult.Position, Color3.new(0, 1, 0))

                self:Destroy()
            end

            local meshPos = self.position + self.meshOffset
            self.mesh.CFrame = CFrame.new(meshPos, meshPos + direction)

            Debug.Point(self.position, Color3.new(1, 0, 0))

            self.position += direction
        else
            self:Destroy()
        end
    end))

    function self:Destroy()
        for _, connection in ipairs(self.connections) do
            connection:Disconnect()
        end

        self.mesh:Destroy()
    end

    return self
end

return Projectile