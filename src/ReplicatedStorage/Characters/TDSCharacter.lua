local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Input = require(ReplicatedStorage.Input)

local VALID_STATES = {
    [Enum.HumanoidStateType.Running] = true,
    [Enum.HumanoidStateType.Dead] = true,
    [Enum.HumanoidStateType.None] = true
}

local TDSCharacter = {}
TDSCharacter.__index = TDSCharacter

function TDSCharacter.new(camera, character)
    local self = {
        camera = camera,
        
        character = character,
        humanoid = character:WaitForChild("Humanoid"),

        connections = {}
    }

    setmetatable(self, TDSCharacter)

    for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if not VALID_STATES[state] then
            self.humanoid:SetStateEnabled(state, false)
        end
    end

    table.insert(self.connections, RunService.Heartbeat:Connect(function()
        self:Update()
    end))

    return self
end
function TDSCharacter:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
end

function TDSCharacter:Update()
    
end

return TDSCharacter