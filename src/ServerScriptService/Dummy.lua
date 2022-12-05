local ServerScriptService = game:GetService("ServerScriptService")

local HitboxHandler = require(ServerScriptService.HitboxHandler)

local RESPAWN_TIME = 5

local Dummy = {}
Dummy.__index = Dummy

function Dummy.new(cframe, parent, moveTargets)
    local self = {
        character = nil,

        origin = cframe,
        parent = parent,

        moveTargets = moveTargets
    }
    setmetatable(self, Dummy)

    self:LoadCharacter()

    return self
end

function Dummy:LoadCharacter()
    self.character = script.Character:Clone()
    self.character:SetPrimaryPartCFrame(self.origin)
    self.character.Parent = self.parent

    local alive = true
    self.character.Humanoid.Died:Connect(function()
        alive = false

        HitboxHandler:RemoveCharacter(self.character)

        wait(RESPAWN_TIME)

        self.character:Destroy()
        self:LoadCharacter()
    end)

    HitboxHandler:AddCharacter(self.character)

    for _, part in ipairs(self.character:GetChildren()) do
        if part:IsA("BasePart") then
            part:SetNetworkOwner(nil)
        end
    end

    local stepper = 1
    if #self.moveTargets > 1 then
        while alive do
            self.character.Humanoid:MoveTo(self.moveTargets[stepper % #self.moveTargets + 1])
            self.character.Humanoid.MoveToFinished:Wait()

            stepper += 1
        end
    end
end

return Dummy