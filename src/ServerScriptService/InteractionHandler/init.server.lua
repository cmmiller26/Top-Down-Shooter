local CollectionService = game:GetService("CollectionService")

local Door = require(script.Door)

for _, interaction in ipairs(CollectionService:GetTagged("Interaction")) do
    if interaction.Type.Value == "Door" then
        Door.new(interaction)
    end
end