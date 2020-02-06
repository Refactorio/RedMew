--[[-- info
    Original (javascript) version: https://hastebin.com/udakacavap.js
    Can be tested against: https://wiki.factorio.com/Enemies#Spawn_chances_by_evolution_factor
]]

-- dependencies
local Global = require 'utils.global'
local Debug = require 'utils.debug'
local table = require 'utils.table'

-- localized functions
local get_random_weighted = table.get_random_weighted
local round = math.round
local ceil = math.ceil
local floor = math.floor
local random = math.random
local pairs = pairs
local format = string.format

-- this
local AlienEvolutionProgress = {}

local memory = {
    spawner_specifications = {},
    spawner_specifications_count = 0,
    evolution_cache = {
        ['biter-spawner'] = {
            evolution = -1,
            weight_table = {},
        },
        ['spitters-spawner'] = {
            evolution = -1,
            weight_table = {},
        },
    },
}

Global.register_init({
    memory = memory,
}, function(tbl)
    for name, prototype in pairs(game.entity_prototypes) do
        if prototype.type == 'unit-spawner' and prototype.subgroup.name == 'enemies' then
            tbl.memory.spawner_specifications[name] = prototype.result_units
            memory.spawner_specifications_count = memory.spawner_specifications_count + 1
        end
    end
end, function(tbl)
    memory = tbl.memory
end)

local function lerp(low, high, pos)
    local s = high.evolution_factor - low.evolution_factor;
    local l = (pos - low.evolution_factor) / s;
    return (low.weight * (1 - l)) + (high.weight * l)
end

local function get_values(map, evolution_factor)
    local result = {}
    local sum = 0

    for _, spawner_data in pairs(map) do
        local list = spawner_data.spawn_points;
        local low = list[1];
        local high = list[#list];

        for _, val in pairs(list) do
            local val_evolution = val.evolution_factor
            if val_evolution <= evolution_factor and val_evolution > low.evolution_factor then
                low = val;
            end
            if val_evolution >= evolution_factor and val_evolution < high.evolution_factor then
                high = val
            end
        end

        local val
        if evolution_factor <= low.evolution_factor then
            val = low.weight
        elseif evolution_factor >= high.evolution_factor then
            val = high.weight;
        else
            val = lerp(low, high, evolution_factor)
        end
        sum = sum + val;

        result[spawner_data.unit] = val;
    end

    local weighted_table = {}
    local count = 0
    for index, _ in pairs(result) do
        count = count + 1
        weighted_table[count] = {index, result[index] / sum}
    end

    return weighted_table;
end

local function get_spawner_values(spawner, evolution)
    local spawner_specification = memory.spawner_specifications[spawner]
    if not spawner_specification then
        Debug.print(format('Spawner "%s" does not exist in the prototype data', spawner))
        return
    end

    local cache = memory.evolution_cache[spawner]

    if not cache then
        cache = {
            evolution = -1,
            weight_table = {},
        }
        memory.evolution_cache[spawner] = cache
    end

    local evolution_value = round(evolution * 100)
    if (cache.evolution < evolution_value) then
        cache.evolution = evolution_value
        cache.weight_table = get_values(spawner_specification, evolution)
    end

    return cache.weight_table
end

local function calculate_total(count, spawner, evolution)
    if count == 0 then
        return {}
    end

    local spawner_values = get_spawner_values(spawner, evolution)
    if not spawner_values then
        return {}
    end

    local aliens = {}
    for _ = 1, count do
        local name = get_random_weighted(spawner_values)
        aliens[name] = (aliens[name] or 0) + 1
    end

    return aliens
end

---Creates the spawner_request structure required for AlienEvolutionProgress.get_aliens for all
---available spawners. If dividing the total spawners by the total aliens causes a fraction, the
---fraction will decide a chance to spawn. 1 alien for 2 spawners will have 50% on both.
---@param total_aliens table
function AlienEvolutionProgress.create_spawner_request(total_aliens)
    local per_spawner = total_aliens / memory.spawner_specifications_count
    local fraction = per_spawner % 1

    local spawner_request = {}
    for spawner, _ in pairs(memory.spawner_specifications) do
        local count = per_spawner
        if fraction > 0 then
            if random() > fraction then
                count = ceil(count)
            else
                count = floor(count)
            end
        end
        spawner_request[spawner] = count
    end

    return spawner_request
end

function AlienEvolutionProgress.get_aliens(spawner_requests, evolution)
    local aliens = {}
    for spawner, count in pairs(spawner_requests) do
        for name, amount in pairs(calculate_total(count, spawner, evolution)) do
            aliens[name] = (aliens[name] or 0) + amount
        end
    end

    return aliens
end

return AlienEvolutionProgress
