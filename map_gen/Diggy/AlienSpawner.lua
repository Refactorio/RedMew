--[[-- info
    Original (javascript) version: https://hastebin.com/udakacavap.js
    Can be tested against: https://wiki.factorio.com/Enemies#Spawn_chances_by_evolution_factor
]]

-- dependencies

-- this
local AlienSpawner = {}

-- values are in the form {evolution, weight}
local biters = {
    {'Small Biter',     {{0.0, 0.3}, {0.6, 0.0}}},
    {'Medium Biter',    {{0.2, 0.0}, {0.6, 0.3}, {0.7, 0.1}}},
    {'Big Biter',       {{0.5, 0.0}, {1.0, 0.4}}},
    {'Behemoth Biter',  {{0.9, 0.0}, {1.0, 0.3}}},
}

local spitters = {
    {'Small Biter',       {{0.0, 0.3}, {0.35, 0.0}}},
    {'Small Spitter',     {{0.25, 0.0}, {0.5, 0.3}, {0.7, 0.0}}},
    {'Medium Spitter',    {{0.4, 0.0}, {0.7, 0.3}, {0.9, 0.1}}},
    {'Big Spitter',       {{0.5, 0.0}, {1.0, 0.4}}},
    {'Behemoth Spitter',  {{0.9, 0.0}, {1.0, 0.3}}},
}

local function lerp(low, high, pos)
    local s = high[1] - low[1];
    local l = (pos - low[1]) / s;
    return (low[2] * (1 - l)) + (high[2] * l)
end

local function get_values(map, evo)
    local result = {}
    local sum = 0

    for _, data in pairs(map) do
        local list = data[2];
        local low = list[1];
        local high = list[#list];

        for _, val in pairs(list) do
            if(val[1] <= evo and val[1] >  low[1]) then
                low = val;
            end
            if(val[1] >= evo and val[1] < high[1]) then
                high = val
            end
        end

        local val
        if (evo <= low[1]) then
            val = low[2]
        elseif (evo >= high[1]) then
            val = high[2];
        else
            val = lerp(low, high, evo)
        end
        sum = sum + val;

        result[data[1]] = val;
    end

    for index, _ in pairs(result) do
        result[index] = result[index] / sum
    end

    return result;
end

function AlienSpawner.getBiterValues(evolution)
    return get_values(biters, evolution)
end

function AlienSpawner.getSpitterValues(evolution)
    return get_values(spitters, evolution)
end

return AlienSpawner
