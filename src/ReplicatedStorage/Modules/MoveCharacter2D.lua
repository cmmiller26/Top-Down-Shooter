local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Input = require(ReplicatedStorage.Input)

local VALID_STATES = {
    [Enum.HumanoidStateType.Running] = true,
    [Enum.HumanoidStateType.Dead] = true,
    [Enum.HumanoidStateType.None] = true
}

local MoveCharacter2D = {}
MoveCharacter2D.__index = MoveCharacter2D

function MoveCharacter2D.new(controller, character)
    local self = {
        mouse = controller.mouse,

        character = character,
        humanoid = character.Humanoid,

        connection = nil
    }
    setmetatable(self, MoveCharacter2D)

    for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if not VALID_STATES[state] then
            self.humanoid:SetStateEnabled(state, false)
        end
    end
    self.humanoid.AutoRotate = false

    self.connection = RunService.Heartbeat:Connect(function()
        self:Update()
    end)

    return self
end
function MoveCharacter2D:Destroy()
    self.connection:Disconnect()
end

function MoveCharacter2D:Update()
    local mouseRay = self.mouse.UnitRay

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {workspace.Baseplate}
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
    local hitPos = raycastResult and raycastResult.Position or mouseRay.Origin + mouseRay.Direction

    local rootPos = self.character.PrimaryPart.Position
    self.character.PrimaryPart.CFrame = CFrame.new(rootPos, Vector3.new(hitPos.X, rootPos.Y, hitPos.Z))

    self.humanoid:Move(Vector3.new(-Input:GetAxis("Horizontal"), 0, Input:GetAxis("Vertical")), false)
end

return MoveCharacter2D