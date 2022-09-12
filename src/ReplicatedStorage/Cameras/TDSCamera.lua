local RunService = game:GetService("RunService")

local DEFAULT_ZOOM = 16
local CAMERA_SPEED = 8

local TDSCamera = {}
TDSCamera.__index = TDSCamera

function TDSCamera.new(camera)
    local self = {
        camera = camera,

        zoom = 1,

        subject = nil,
    }

    setmetatable(self, TDSCamera)

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
        local targetCFrame = CFrame.new(self.subject.Position + Vector3.new(0, DEFAULT_ZOOM * self.zoom, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
        self.camera.CFrame = self.camera.CFrame:Lerp(targetCFrame, deltaTime * CAMERA_SPEED)
    end
end

return TDSCamera