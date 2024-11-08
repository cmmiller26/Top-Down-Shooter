local InteractPart = {}
InteractPart.__index = InteractPart

function InteractPart.new(character, gui)
    local self = {
        gui = gui,

        collider = nil,

        curInteract = nil
    }
    setmetatable(self, InteractPart)

    self.collider = script.Interact:Clone()
    self.collider.Weld.Part0 = character.PrimaryPart
    self.collider.Parent = character

    local interactions = {}
    self.collider.Touched:Connect(function(part)
        if part.CollisionGroup == "Interact" then
            local interact = part.Parent
            table.insert(interactions, interact)

            self.curInteract = interact

            self.gui:Prompt(true, self.curInteract)
        end
    end)
    self.collider.TouchEnded:Connect(function(part)
        if part.CollisionGroup == "Interact" then
            for index, value in ipairs(interactions) do
                if value.PrimaryPart == part or value.PrimaryPart == nil then
                    table.remove(interactions, index)
                end
            end
            self.curInteract = select(2, next(interactions))

            if self.curInteract then
                self.gui:Prompt(true, self.curInteract)
            else
                self.gui:Prompt(false)
            end
        end
    end)

    return self
end
function InteractPart:Destroy()
    self.collider:Destroy()
end

function InteractPart:GetInteract()
    return self.curInteract
end

return InteractPart