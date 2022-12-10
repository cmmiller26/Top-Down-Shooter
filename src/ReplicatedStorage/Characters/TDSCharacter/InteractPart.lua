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

    local items = {}
    self.collider.Touched:Connect(function(otherPart)
        if otherPart.CollisionGroup == "Interact" then
            local interact = otherPart.Parent
            if interact.Type.Value == "Script" then
                self.curInteract = otherPart.Parent

                self.interactGui.Label.Text = require(self.curInteract:FindFirstChildWhichIsA("ModuleScript")).GetPopup()
                self.interactGui.Visible = true
            elseif interact.Type.Value == "Item" then
                table.insert(items, interact)
                self.curInteract = interact

                self.interactGui.Label.Text = "Pickup " .. self.curInteract.Name
                self.interactGui.Visible = true
            end
        end
    end)
    self.collider.TouchEnded:Connect(function(otherPart)
        if otherPart.CollisionGroup == "Interact" then
            local interact = otherPart.Parent
            if interact.Type.Value == "Interact" then
                self.curInteract = nil

                self.interactGui.Visible = false
                self.interactGui.Label.Text = ""
            elseif interact.Type.Value == "Item" then
                for index, item in ipairs(items) do
                    if item.PrimaryPart == otherPart or item.PrimaryPart == nil then
                        table.remove(items, index)
                    end
                end
                self.curInteract = select(2, next(items))

                if self.curInteract then
                    self.interactGui.Label.Text = "Pickup " .. self.curInteract.Name
                else
                    self.interactGui.Visible = false
                    self.interactGui.Label.Text = ""
                end
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