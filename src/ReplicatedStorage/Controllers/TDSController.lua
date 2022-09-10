local TDSController = {}

function TDSController.new(player, camera)
    local self = {
        player = player,
        camera = camera,

        characters = {},

        connections = {}
    }

    setmetatable(self, TDSController)

    table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(character)
    end))
    table.insert(self.connections, self.player.CharacterRemoving:Connect(function(character)
        self:CharacterRemoving(character)
    end))

    return self
end
function TDSController:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
end

function TDSController:CharacterAdded(character)

end
function TDSController:CharacterRemoving(character)

end

function TDSController:Died()

end

return TDSController