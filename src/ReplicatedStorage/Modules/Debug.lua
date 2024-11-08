local Debris = game:GetService("Debris")

local Debug = {
    enabled = false,

    lifetime = 2
}

function Debug.Point(position, color)
    if Debug.enabled then
        local point = Instance.new("SphereHandleAdornment")
        point.Color3 = color
        point.Adornee = workspace.Terrain
        point.AlwaysOnTop = true
        point.Name = "Debug Point"
        point.Radius = 0.12
        point.ZIndex = 1
        point.CFrame = CFrame.new(position)
        point.Parent = workspace.Terrain.Debug
        Debris:AddItem(point, Debug.lifetime)
    end
end

function Debug.Vector(startPos, endPos, color)
    if Debug.enabled then
        local vector = Instance.new("BoxHandleAdornment")
        vector.Color3 = color
        vector.Adornee = workspace.Terrain
        vector.AlwaysOnTop = true
        vector.Name = "Debug Vector"
        vector.ZIndex = 1

        local direction = (endPos - startPos)
        local size = direction.Magnitude
        vector.Size = Vector3.new(0.12, 0.12, size)
        vector.CFrame = CFrame.new(startPos + (direction/2), endPos)
        vector.Parent = workspace.Terrain.Debug
        Debris:AddItem(vector, Debug.lifetime)
    end
end

return Debug