local Functions = {}

function Functions.InTable(a, tbl)
    for _, b in ipairs(tbl) do
        if b == a then
            return true
        end
    end
    return false
end

return Functions