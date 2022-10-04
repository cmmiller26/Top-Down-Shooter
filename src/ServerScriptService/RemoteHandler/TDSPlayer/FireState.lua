local FireState = {}

function FireState.new(origin, direction, speed, damage, playerTick)
    return {
        origin = origin,
        direction = direction,
        speed = speed,
        damage = damage,
        playerTick = playerTick
    }
end

return FireState