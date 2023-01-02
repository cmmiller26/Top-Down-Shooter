local UserInputService = game:GetService("UserInputService")

local Input = {}
Input.__index = Input

function Input.new()
    local self = {
        axes = {
            Horizontal = {
                value = 0,
                addButton = Enum.KeyCode.D,
                subtractButton = Enum.KeyCode.A
            },
            Vertical = {
                value = 0,
                addButton = Enum.KeyCode.W,
                subtractButton = Enum.KeyCode.S
            }
        },

        keysDown = {}
    }
    setmetatable(self, Input)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for _, axis in pairs(self.axes) do
                if input.KeyCode == axis.addButton then
                    axis.value = 1
                elseif input.KeyCode == axis.subtractButton then
                    axis.value = -1
                end
            end

            self.keysDown[input.KeyCode] = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for _, axis in pairs(self.axes) do
                if input.KeyCode == axis.addButton then
                    axis.value = self.keysDown[axis.subtractButton] and -1 or 0
                elseif input.KeyCode == axis.subtractButton then
                    axis.value = self.keysDown[axis.addButton] and 1 or 0
                end
            end

            self.keysDown[input.KeyCode] = nil
        end
    end)

    return self
end

function Input:GetAxis(axisName)
    return self.axes[axisName].value
end
function Input:GetKeyDown(keyCode)
    return self.keysDown[keyCode]
end

return Input.new()