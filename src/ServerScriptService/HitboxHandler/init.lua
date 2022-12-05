local RunService = game:GetService("RunService")

local HitboxState = require(script.HitboxState)

local FIXED_DELTA_TIME = 1/60

local MAX_STATES = 120

local TICK_BUFFER = math.round(0.1 / FIXED_DELTA_TIME)

local HitboxHandler = {}
HitboxHandler.__index = HitboxHandler

function HitboxHandler.new()
    local self = {
        characters = {},

        hitboxStates = {},

        accumulator = 0,
        serverTick = 0
    }
    setmetatable(self, HitboxHandler)

    RunService.Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
    end)

    return self
end

function HitboxHandler:Update(deltaTime)
    self.accumulator += deltaTime
    while self.accumulator >= FIXED_DELTA_TIME do
        self.serverTick += 1
        for _, character in ipairs(self.characters) do
            self.hitboxStates[character][self.serverTick % MAX_STATES] = HitboxState.new(character)
        end

        self.accumulator -= FIXED_DELTA_TIME
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

function HitboxHandler:GetHitboxState(targetCharacter, ping)
    for character, states in pairs(self.hitboxStates) do
        if character == targetCharacter then
            local tickDiff = math.round(ping / FIXED_DELTA_TIME) + TICK_BUFFER
            local curTick = self.serverTick - tickDiff
            return states[curTick % MAX_STATES]
        end
    end
    return nil
end

return HitboxHandler.new()