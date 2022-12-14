local InteractPart = {}
InteractPart.__index = InteractPart

function InteractPart.new(character, frame)
    local self = {
        interactGui = frame,

        collider = nil,

        curInteract = nil
    }
    setmetatable(self, InteractPart)

    self.collider = script.Interact:Clone()
    self.collider.Weld.Part0 = character.PrimaryPart
    self.collider.Parent = character

    local function GetLabel(interact)
        if interact.Type.Value == "Script" then
            return require(self.curInteract:FindFirstChildWhichIsA("ModuleScript")).GetPopup()
        elseif interact.Type.Value == "Item" then
            return "Pickup " .. self.curInteract.Name
        end
    end

    local interactions = {}
    self.collider.Touched:Connect(function(part)
        if part.CollisionGroup == "Interact" then
            local interact = part.Parent
            table.insert(interactions, interact)

            self.curInteract = interact

            self.interactGui.Label.Text = GetLabel(self.curInteract)
            self.interactGui.Visible = true
        end
    end)
    self.collider.TouchEnded:Connect(function(part)
        if part.CollisionGroup == "Interact" then
            local interact = part.Parent
            for index, value in ipairs(interactions) do
                if value.PrimaryPart == part or value.PrimaryPart == nil then
                    table.remove(interactions, index)
                end
            end
            self.curInteract = select(2, next(interactions))

            if self.curInteract then
                self.interactGui.Label.Text = GetLabel(self.curInteract)
            else
                self.interactGui.Visible = false
                self.interactGui.Label.Text = ""
            end
        end
    end)

    return self
end
function InteractPart:Destroy()
    self.interactGui.Visible = false
    self.interactGui.Label.Text = ""

    self.collider:Destroy()
end

function InteractPart:GetInteract()
    return self.curInteract
end

return InteractPart