local InteractPart = {}
InteractPart.__index = InteractPart

function InteractPart.new(character, frame)
    local self = {
        pickupGui = frame,

        collider = nil,
        curItem = nil
    }
    setmetatable(self, InteractPart)

    self.collider = script.Collider:Clone()
    self.collider.Weld.Part0 = character.PrimaryPart
    self.collider.Parent = character

    local items = {}
    self.collider.Touched:Connect(function(otherPart)
        if otherPart.CollisionGroup == "Collider" then
            local item = otherPart.Parent
            if item:FindFirstChild("Item") then
                table.insert(items, item)
                self.curItem = item

                self.pickupGui.Label.Text = "Pickup " .. self.curItem.Name
                self.pickupGui.Visible = true
            end
        end
    end)
    self.collider.TouchEnded:Connect(function(otherPart)
        if otherPart.CollisionGroup == "Collider" then
            for index, item in ipairs(items) do
                if item.PrimaryPart == otherPart or item.PrimaryPart == nil then
                    table.remove(items, index)
                end
            end
            self.curItem = select(2, next(items))

            if self.curItem then
                self.pickupGui.Label.Text = "Pickup " .. self.curItem.Name
            else
                self.pickupGui.Visible = false
                self.pickupGui.Label.Text = ""
            end
        end
    end)

    return self
end
function InteractPart:Destroy()
    self.pickupGui.Visible = false
    self.pickupGui.Label.Text = ""

    self.collider:Destroy()
end

function InteractPart:GetItem()
    return self.curItem
end

return InteractPart