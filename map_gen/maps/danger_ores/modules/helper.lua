local Public = {}

function Public.split_ore(ores, split_count)
    local new_ores = {}
    for _ = 1, split_count do
        for _, ore in pairs(ores) do
            new_ores[#new_ores + 1] = ore
        end
    end

    return new_ores
end

return Public