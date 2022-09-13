local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FOV = 30

local OFFSET = Vector3.new(0, 40, -10)
local SPEED = 8

local OBSCURE_TRANSPARENCY = 0.75
local TWEEN_TIME = 0.25

local TDSCamera = {}
TDSCamera.__index = TDSCamera

local function inList(a, tbl)
    for _, b in ipairs(tbl) do
        if b == a then
            return true
        end
    end
    return false
end
local function inDictionary(a, dict)
    for b, _ in pairs(dict) do
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
        local targetPos = self.subject.PrimaryPart.Position
        local targetCFrame = CFrame.new(targetPos + OFFSET * self.zoom, targetPos)
        self.camera.CFrame = self.camera.CFrame:Lerp(targetCFrame, deltaTime * SPEED)

        local obscuring = self.camera:GetPartsObscuringTarget({targetPos}, {self.subject})
        for _, part in ipairs(obscuring) do
            if part:FindFirstChild("Obscure") and not inDictionary(part, self.obscuring) then
                self.obscuring[part] = part.Transparency
                TweenService:Create(part, TweenInfo.new(TWEEN_TIME), {Transparency = OBSCURE_TRANSPARENCY}):Play()
            end
        end

        for part, transparency in pairs(self.obscuring) do
            if not inList(part, obscuring) then
                TweenService:Create(part, TweenInfo.new(TWEEN_TIME), {Transparency = transparency}):Play()
                self.obscuring[part] = nil
            end
        end
    end
end

return TDSCamera