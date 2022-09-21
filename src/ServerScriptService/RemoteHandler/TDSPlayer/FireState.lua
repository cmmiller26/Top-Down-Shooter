local FireState = {}

function FireState.new(origin, direction, fireID, playerTick)
    return {
        origin = origin,
        direction = direction,
        fireID = fireID,
        playerTick = playerTick
    }
end

return FireState