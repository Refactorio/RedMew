--[[-- info
    Original (javascript) version: https://hastebin.com/udakacavap.js
    Can be tested against: https://wiki.factorio.com/Enemies#Spawn_chances_by_evolution_factor
]]

-- dependencies
local Global = require 'utils.global'
local random = math.random
local round = math.round

-- this
local AlienEvolutionProgress = {}

local alien_cache = {
    biters = {
        evolution = -1,
        cache = {},
    },
    spitters = {
        evolution = -1,
        cache = {},
    },
}

Global.register({
    alien_cache = alien_cache,
}, function(tbl)
    alien_cache = tbl.alien_cache
end)

-- values are in the form {evolution, weight}
local biters = {
    {'small-biter',     {{0.0, 0.3}, {0.6, 0.0}}},
    {'medium-biter',    {{0.2, 0.0}, {0.6, 0.3}, {0.7, 0.1}}},
    {'big-biter',       {{0.5, 0.0}, {1.0, 0.4}}},
    {'behemoth-biter',  {{0.9, 0.0}, {1.0, 0.3}}},
}

local spitters = {
    {'small-biter',       {{0.0, 0.3}, {0.35, 0.0}}},
    {'small-spitter',     {{0.25, 0.0}, {0.5, 0.3}, {0.7, 0.0}}},
    {'medium-spitter',    {{0.4, 0.0}, {0.7, 0.3}, {0.9, 0.1}}},
    {'big-spitter',       {{0.5, 0.0}, {1.0, 0.4}}},
    {'behemoth-spitter',  {{0.9, 0.0}, {1.0, 0.3}}},
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

local function get_name_by_random(collection)
    local pre_calculated = random()
    local current = 0

    for name, probability in pairs(collection) do
        current = current + probability
        if (current >= pre_calculated) then
            return name
        end
    end

    Debug.print('AlienEvolutionProgress.get_name_by_random: Current \'' .. current .. '\' should be higher or equal to random \'' .. pre_calculated .. '\'')
end

function AlienEvolutionProgress.getBiterValues(evolution)
    local evolution_value = round(evolution * 100)

    if (alien_cache.biters.evolution < evolution_value) then
        alien_cache.biters.evolution = evolution_value
        alien_cache.biters.cache = get_values(biters, evolution)
    end

    return alien_cache.biters.cache
end

function AlienEvolutionProgress.getSpitterValues(evolution)
    local evolution_value = round(evolution * 100)

    if (alien_cache.spitters.evolution < evolution_value) then
        alien_cache.spitters.evolution = evolution_value
        alien_cache.spitters.cache = get_values(spitters, evolution)
    end

    return alien_cache.spitters.cache
end

function AlienEvolutionProgress.getBitersByEvolution(total_biters, evolution)
    local biters_calculated = {}
    local map = AlienEvolutionProgress.getBiterValues(evolution)

    for i = 1, total_biters do
        local name = get_name_by_random(map)
        if (nil == biters_calculated[name]) then
            biters_calculated[name] = 1
        else
            biters_calculated[name] = biters_calculated[name] + 1
        end
    end

    return biters_calculated
end

function AlienEvolutionProgress.getSpittersByEvolution(total_spitters, evolution)
    local spitters_calculated = {}
    local map = AlienEvolutionProgress.getSpitterValues(evolution)

    for i = 1, total_spitters do
        local name = get_name_by_random(map)
        if (nil == spitters_calculated[name]) then
            spitters_calculated[name] = 1
        else
            spitters_calculated[name] = spitters_calculated[name] + 1
        end
    end

    return spitters_calculated
end

return AlienEvolutionProgress
