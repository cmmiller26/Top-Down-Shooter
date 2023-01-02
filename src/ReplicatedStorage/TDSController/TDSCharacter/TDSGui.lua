local TDSGui = {}
TDSGui.__index = TDSGui

function TDSGui.new(character)
    local self = {
        character = character,

        gui = nil,
    }
    setmetatable(self, TDSGui)

    self.gui = script.ScreenGui:Clone()

    return self
end
function TDSGui:Destroy()
    self.gui:Destroy()
end

function TDSGui:SetParent(parent)
    self.gui.Parent = parent
end

return TDSGui