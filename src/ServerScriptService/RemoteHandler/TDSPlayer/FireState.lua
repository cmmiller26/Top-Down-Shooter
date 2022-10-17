local FireState = {}

function FireState.new(origin, direction, speed, damage)
    return {
        origin = origin,
        direction = direction,
        speed = speed,
        damage = damage,
        serverTick = tick()
    }
end

return FireState