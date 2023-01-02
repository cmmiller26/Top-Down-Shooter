local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)

require(ReplicatedStorage.PingTimes)

local Controllers = {
    ReplicatedStorage.TDSController,
}

local PlayerModule = {}
PlayerModule.__index = PlayerModule

function PlayerModule.new()
    local self = {
        player = Players.LocalPlayer,
        camera = workspace.CurrentCamera,

        controller = nil,
    }
    setmetatable(self, PlayerModule)

    self:ConnectControllers()

    return self
end

function PlayerModule:ConnectControllers()
    for _, controller in ipairs(Controllers) do
        controller.Remotes.Connect.OnClientEvent:Connect(function()
            if self.controller then
                self.controller:Destroy()
            end

            self.controller = require(controller).new(self.player, self.camera)
        end)
    end
end

return PlayerModule.new()