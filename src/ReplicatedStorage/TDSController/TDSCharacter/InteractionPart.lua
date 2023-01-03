local InteractionPart = {}
InteractionPart.__index = InteractionPart

function InteractionPart.new(character, gui)
    local self = {
        gui = gui,

        part = nil,

        interactions = {},
        interaction = nil,
    }
    setmetatable(self, InteractionPart)

    self.part = script.InteractionPart:Clone()
    self.part.Weld.Part0 = character.PrimaryPart
    self.part.Parent = character

    self.part.Touched:Connect(function(part)
        self:Touched(part)
    end)
    self.part.TouchEnded:Connect(function(part)
        self:TouchEnded(part)
    end)

    return self
end
function InteractionPart:Destroy()
    self.part:Destroy()
end

function InteractionPart:Touched(part)
    if part.CollisionGroup == "Interact" then
        self.interaction = part.Parent
        table.insert(self.interactions, self.interaction)

        self.gui:Prompt(true, self.interaction)
    end
end
function InteractionPart:TouchEnded(part)
    if part.CollisionGroup == "Interact" then
        for index, value in ipairs(self.interactions) do
            if value.PrimaryPart == part or value.PrimaryPart == nil then
                table.remove(self.interactions, index)
            end
        end
        self.interaction = select(2, next(self.interactions))

        if self.interaction then
            self.gui:Prompt(true, self.interaction)
        else
            self.gui:Prompt(false)
        end
    end
end

function InteractionPart:GetInteraction()
    return self.interaction
end

return InteractionPart