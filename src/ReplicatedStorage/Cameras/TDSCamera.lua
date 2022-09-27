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

function TDSCamera:ChangeZoom(zoom)
    self.zoom = zoom
end
function TDSCamera:ChangeSubject(subject)
    self.subject = subject
end

function TDSCamera:Update(deltaTime)
    if self.subject then
        local zoom = self.zoom
        local targetPos = self.subject.PrimaryPart.Position

        local obscuring = self.camera:GetPartsObscuringTarget({targetPos + Vector3.new(0, 2, 0), targetPos + Vector3.new(0, -3, 0)}, {self.subject})
        for _, part in ipairs(obscuring) do
            if part:FindFirstChild("Obscure") and not inTable(part, self.obscuring) then
                table.insert(self.obscuring, part)
                TweenService:Create(part, TweenInfo.new(TWEEN_TIME), {Transparency = part.Obscure.Value.Y}):Play()
            end
        end

        for index, part in pairs(self.obscuring) do
            if not inTable(part, obscuring) then
                TweenService:Create(part, TweenInfo.new(TWEEN_TIME), {Transparency = part.Obscure.Value.X}):Play()
                table.remove(self.obscuring, index)
            end

            if part.Obscure.Value.Y >= 1 then
                zoom = 1
            end
        end

        local targetCFrame = CFrame.new(targetPos + OFFSET * zoom, targetPos)
        self.camera.CFrame = self.camera.CFrame:Lerp(targetCFrame, deltaTime * SPEED)
    end
end

return TDSCamera