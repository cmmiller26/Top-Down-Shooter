local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Functions = require(ReplicatedStorage.Modules.Functions)

local TDSCamera = {}
TDSCamera.__index = TDSCamera

function TDSCamera.new(camera)
    local self = {
        camera = camera,

        zoom = 1,
        subject = nil,

        obscuring = {},
    }
    setmetatable(self, TDSCamera)

    self.camera.CameraType = Enum.CameraType.Scriptable
    self.camera.FieldOfView = script.FieldOfView.Value

    RunService:BindToRenderStep("TDSCamera", Enum.RenderPriority.Camera.Value, function(deltaTime)
        self:Update(deltaTime)
    end)

    return self
end
function TDSCamera:Destroy()
    RunService:UnbindFromRenderStep("TDSCamera")
end

function TDSCamera:SetZoom(value)
    self.zoom = value
end
function TDSCamera:SetSubject(value)
    self.subject = value
end

local function Raycast(origin, direction, results)
    local raycastParams = RaycastParams.new()
    raycastParams.CollisionGroup = "NoCollide"
    raycastParams.FilterDescendantsInstances = results
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        table.insert(results, raycastResult.Instance)
        return Raycast(origin, direction, results)
    else
        return results
    end
end
function TDSCamera:Update(deltaTime)
    if self.subject then
        local zoom = self.zoom
        local targetPos = self.subject.PrimaryPart.Position

        local origin = self.camera.CFrame.Position
        local direction = targetPos - origin

        local obscuring = Raycast(origin, direction)
        for _, part in ipairs(obscuring) do
            if not Functions.InTable(part, self.obscuring) then
                table.insert(self.obscuring, part)
                TweenService:Create(part, TweenInfo.new(script.PartObscureTime.Value), {Transparency = part.Obscure.Value}):Play()
            end
        end

        for index, part in ipairs(self.obscuring) do
            if not Functions.InTable(part, obscuring) then
                TweenService:Create(part, TweenInfo.new(script.PartObscureTime.Value), {Transparency = part.Default.Value}):Play()
                table.remove(self.obscuring, index)
            end

            if part:FindFirstChild("Zoom") then
                zoom = part.Zoom.Value
            elseif zoom >= 2 then
                zoom /= 2
            end
        end

        local targetCFrame = CFrame.new(targetPos + script.CameraOffset.Value * zoom, targetPos)
        self.camera.CFrame = self.camera.CFrame:Lerp(targetCFrame, deltaTime * script.CameraSpeed.Value)
    end
end

return TDSCamera