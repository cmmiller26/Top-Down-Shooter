local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Modules.PingTimes)

local TDSController = require(ReplicatedStorage.Controllers.TDSController)

local PlayerModule = {}
PlayerModule.__index = PlayerModule

function PlayerModule.new()
    local self = {
        player = Players.LocalPlayer,
        camera = workspace.CurrentCamera,

        controller = nil
    }

    setmetatable(self, PlayerModule)

    self.controller = TDSController.new(self.player, self.camera)

    return self
end

return PlayerModule.new()