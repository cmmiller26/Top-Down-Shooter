local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FOV = 30

local OFFSET = Vector3.new(0, 40, -10)
local SPEED = 8

local TWEEN_TIME = 0.25

local TDSCamera = {}
TDSCamera.__index = TDSCamera

local function inTable(a, tbl)
    for _, b in ipairs(tbl) do
        if b == a then
            return true
        end
    end
    return false
end

function TDSCamera.new(camera)
    local self = {
        camera = camera,

        zoom = 1,

        subject = nil,

        obscuring = {}
    }
    setmetatable(self, TDSCamera)

    self.camera.CameraType = Enum.CameraType.Scriptable
    self.camera.FieldOfView = FOV

    RunService:BindToRenderStep("UpdateTDSCamera", Enum.RenderPriority.Camera.Value, function(deltaTime)
        self:Update(deltaTime)
    end)

    return self
end
function TDSCamera:Destroy()
    RunService:UnbindFromRenderStep("UpdateTDSCamera")
end

function TDSCamera:Zoom(zoom)
    self.zoom = zoom
end
function TDSCamera:Subject(subject)
    self.subject = subject
end

local function Raycast(origin, direction, results)
    if not results then
        results = {}
    end

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
            if not inTable(part, self.obscuring) then
                table.insert(self.obscuring, part)
                TweenService:Create(part, TweenInfo.new(TWEEN_TIME), {Transparency = part.Obscure.Value}):Play()
            end
        end

        for index, part in ipairs(self.obscuring) do
            if not inTable(part, obscuring) then
                TweenService:Create(part, TweenInfo.new(TWEEN_TIME), {Transparency = part.Default.Value}):Play()
                table.remove(self.obscuring, index)
            end

            if part:FindFirstChild("Zoom") then
                zoom = part.Zoom.Value
            elseif zoom >= 2 then
                zoom /= 2
            end
        end

        local targetCFrame = CFrame.new(targetPos + OFFSET * zoom, targetPos)
        self.camera.CFrame = self.camera.CFrame:Lerp(targetCFrame, deltaTime * SPEED)
    end
end

return TDSCamera