local ServerScriptService = game:GetService("ServerScriptService")

local HitboxHandler = require(ServerScriptService.HitboxHandler)

local RESPAWN_TIME = 5

local Dummy = {}
Dummy.__index = Dummy

function Dummy.new(cframe, parent)
    local self = {
        character = nil,

        origin = cframe,

        parent = parent
    }

    setmetatable(self, Dummy)

    self:LoadCharacter()

    return self
end

function Dummy:LoadCharacter()
    self.character = script.Character:Clone()
    self.character:SetPrimaryPartCFrame(self.origin)
    self.character.Parent = self.parent

    self.character.Humanoid.Died:Connect(function()
        HitboxHandler:RemoveCharacter(self.character)

        wait(RESPAWN_TIME)

        self.character:Destroy()
        self:LoadCharacter()
    end)

    HitboxHandler:AddCharacter(self.character)
end

return Dummy