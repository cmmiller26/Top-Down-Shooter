local RunService = game:GetService("RunService")

local HitboxState = require(script.HitboxState)
local MakeHitbox = require(script.MakeHitbox)

local MAX_STATES = 120

local HitboxHandler = {}
HitboxHandler.__index = HitboxHandler

function HitboxHandler.new()
    local self = {
        characters = {},

        hitboxStates = {},

        deltaTime = 0,
        serverTick = 0,
    }

    setmetatable(self, HitboxHandler)

    RunService.Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
    end)

    return self
end

function HitboxHandler:Update(deltaTime)
    self.deltaTime = deltaTime
    self.serverTick += 1

    for _, character in ipairs(self.characters) do
        self.hitboxStates[character][self.serverTick % MAX_STATES] = HitboxState.new(character)
    end
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

function HitboxHandler:GetHitboxState(targetCharacter, playerTick)
    for character, states in pairs(self.hitboxStates) do
        if character == targetCharacter then
            local tickDiff = math.max(0, math.round((tick() - playerTick) / self.deltaTime))
            local curTick = self.serverTick - tickDiff
            return states[curTick % MAX_STATES]
        end
    end
    return nil
end

function HitboxHandler:GetHitbox(targetCharacter, playerTick)
    for character, states in pairs(self.hitboxStates) do
        if character == targetCharacter then
            local tickDiff = math.round((tick() - playerTick) / self.deltaTime)
            local curTick = self.serverTick - tickDiff
            return MakeHitbox(states[curTick % MAX_STATES])
        end
    end
    return nil
end

return HitboxHandler.new()