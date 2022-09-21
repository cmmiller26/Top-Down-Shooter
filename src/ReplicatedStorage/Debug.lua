local Debris = game:GetService("Debris")

local LIFETIME = 2

local Debug = {
    enabled = true
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
        game:GetService("Debris"):AddItem(point, LIFETIME)
    end
end

return Debug