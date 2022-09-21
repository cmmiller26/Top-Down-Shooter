local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Debug = require(ReplicatedStorage.Debug)

local Projectile = {}

function Projectile.new(origin, velocity, distance, raycastParams)
    local self = {
        origin = origin,
        position = origin,

        velocity = velocity,

        distance = distance,

        raycastParams = raycastParams,

        connections = {}
    }

    table.insert(self.connections, RunService.Heartbeat:Connect(function(deltaTime)
        if (self.position - self.origin).Magnitude < self.distance then
            local direction = self.velocity * deltaTime

            local raycastResult = workspace:Raycast(self.position, direction, self.raycastParams)
            if raycastResult then
                Debug.Point(raycastResult.Position, Color3.new(0, 1, 0))

                self:Destroy()
            end

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
    end

    return self
end

return Projectile