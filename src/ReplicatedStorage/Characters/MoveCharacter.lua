local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Input = require(ReplicatedStorage.Input)

local VALID_STATES = {
    [Enum.HumanoidStateType.Running] = true,
    [Enum.HumanoidStateType.Dead] = true,
    [Enum.HumanoidStateType.None] = true
}

local MoveCharacter = {}
MoveCharacter.__index = MoveCharacter

function MoveCharacter.new(mouse, character)
    local self = {
        mouse = mouse,

        character = character,
        humanoid = character:WaitForChild("Humanoid"),

        connections = {}
    }
    
    setmetatable(self, MoveCharacter)

    for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if not VALID_STATES[state] then
            self.humanoid:SetStateEnabled(state, false)
        end
    end
    self.humanoid.AutoRotate = false

    table.insert(self.connections, RunService.Heartbeat:Connect(function()
        self:Update()
    end))

    return self
end
function MoveCharacter:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
end

function MoveCharacter:Update()
    local mouseRay = self.mouse.UnitRay

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {workspace.Baseplate}
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
    local hitPos = raycastResult and raycastResult.Position or mouseRay.Origin + mouseRay.Direction

    local rootPos = self.character.PrimaryPart.Position
    self.character.PrimaryPart.CFrame = CFrame.new(rootPos, Vector3.new(hitPos.X, rootPos.Y, hitPos.Z))

    local wishDir = Vector3.new(-Input:GetAxis("Horizontal"), 0, Input:GetAxis("Vertical"))
    self.humanoid:Move(wishDir, false)
end

return MoveCharacter