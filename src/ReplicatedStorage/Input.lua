local UserInputService = game:GetService("UserInputService")

local Input = {}
Input.__index = Input

function Input.new()
    local self = {
        axes = {
            Horizontal = {
                Value = 0,
                AddButton = Enum.KeyCode.D,
                SubtractButton = Enum.KeyCode.A
            },
            Vertical = {
                Value = 0,
                AddButton = Enum.KeyCode.W,
                SubtractButton = Enum.KeyCode.S
            }
        },

        keysDown = {}
    }

    setmetatable(self, Input)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for _, axis in pairs(self.axes) do
                if input.KeyCode == axis.AddButton then
                    axis.Value = 1
                elseif input.KeyCode == axis.SubtractButton then
                    axis.Value = -1
                end
            end

            self.keysDown[input.KeyCode] = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            for _, axis in pairs(self.axes) do
                if input.KeyCode == axis.AddButton then
                    axis.Value = self.keysDown[axis.SubtractButton] and -1 or 0
                elseif input.KeyCode == axis.SubtractButton then
                    axis.Value = self.keysDown[axis.AddButton] and 1 or 0
                end
            end

            self.keysDown[input.KeyCode] = nil
        end
    end)

    return self
end

function Input:GetAxis(axis)
    return self.axes[axis].Value
end
function Input:GetKeyDown(keyCode)
    return self.keysDown[keyCode]
end

return Input.new()