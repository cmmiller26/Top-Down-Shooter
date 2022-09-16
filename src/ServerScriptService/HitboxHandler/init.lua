local RunService = game:GetService("RunService")

local HitboxState = require(script.HitboxState)
local MakeHitboxCharacter = require(script.MakeHitboxCharacter)

local MAX_STATES = 120

local HitboxHandler = {}
HitboxHandler.__index = HitboxHandler

function HitboxHandler.new()
    local self = {
        characters = {},

        hitboxStates = {},
        serverTick = 0
    }

    setmetatable(self, HitboxHandler)

    RunService.Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
    end)

    return self
end

function HitboxHandler:Update(deltaTime)
    for _, character in ipairs(self.characters) do
        self.hitboxStates[character][self.serverTick] = HitboxState.new(character)
        local hitboxCharacter = MakeHitboxCharacter(self.hitboxStates[character][self.serverTick])
        hitboxCharacter.Parent = workspace
        game:GetService("Debris"):AddItem(hitboxCharacter, 2)
    end

    self.serverTick += 1
end

function HitboxHandler:AddCharacter(character)
    table.insert(self.characters, character)
    self.hitboxStates[character] = {}
end
function HitboxHandler:RemoveCharacter(character)
    for index, otherCharacter in ipairs(self.characters) do
        if otherCharacter == character then
            self.hitboxStates[character] = nil
            table.remove(self.characters, index)
            break
        end
    end
end

return HitboxHandler.new()