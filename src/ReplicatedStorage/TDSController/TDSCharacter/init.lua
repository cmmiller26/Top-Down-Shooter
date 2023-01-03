local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameSettings = require(ReplicatedStorage.GameSettings)

local TDSGui = require(script.TDSGui)
local InteractionPart = require(script.InteractionPart)

local TDSCharacter = {}
TDSCharacter.__index = TDSCharacter

function TDSCharacter.new(player, character)
    local self = {
        character = character,

        gui = nil,

        interactionPart = nil,
    }
    setmetatable(self, TDSCharacter)

    self.gui = TDSGui.new(self.character)
    self.gui:SetParent(player)

    self.interactionPart = InteractionPart.new(self.character, self.gui)

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

function TDSCharacter:Interact(bool)
    local interaction = self.interactionPart:GetInteraction()
    if interaction and bool then
        
    end
end