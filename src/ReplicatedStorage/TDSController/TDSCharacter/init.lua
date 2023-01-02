local ContextActionService = game:GetService("ContextActionService")

local TDSGui = require(script.TDSGui)

local TDSCharacter = {}
TDSCharacter.__index = TDSCharacter

function TDSCharacter.new(controller, character)
    local self = {
        controller = controller,

        character = character,

        gui = nil,
    }
    setmetatable(self, TDSCharacter)

    self.gui = TDSGui.new(self)
    self.gui:SetParent(controller.player)

    self:BindActions()

    return self
end
function TDSCharacter:Destroy()
    self:UnbindActions()

    self.gui:Destroy()
end

function TDSCharacter:BindActions()
    local function onInteract(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self:Interact(true)
        elseif inputState == Enum.UserInputState.End then
            self:Interact(false)
        end
    end
    ContextActionService:BindAction("TDSInteract", onInteract, false, Enum.KeyCode.F)
end
function TDSCharacter:UnbindActions()
    ContextActionService:UnbindAction("TDSInteract")
end

function TDSCharacter:Interact()
    
end