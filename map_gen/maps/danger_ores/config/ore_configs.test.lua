-- Standalone unit tests for the danger-ores ore configs.
-- Run from the repo root:  lua map_gen/maps/danger_ores/config/ore_configs.test.lua
package.path = './?.lua;' .. package.path

-- stub the builders so configs load outside Factorio; value functions become readable tags
local fake_builders = { full_shape = 'FULL' }
function fake_builders.euclidean_value(base, mult)
    return ('euclid(%s,%s)'):format(base, mult)
end
function fake_builders.exponential_value(base, mult, pow)
    return ('exp(%s,%s,%s)'):format(base, mult, pow)
end
function fake_builders.resource(_, name, value)
    return { kind = 'resource', name = name, value = value }
end
setmetatable(fake_builders, {
    __index = function(_, k)
        return function()
            return 'builders.' .. k
        end
    end,
})
package.loaded['map_gen.shared.builders'] = fake_builders

local failures = 0
local function check(cond, msg)
    if cond then
        print('ok:   ' .. msg)
    else
        failures = failures + 1
        print('FAIL: ' .. msg)
    end
end

local function load_config(name)
    return require('map_gen.maps.danger_ores.config.' .. name)
end

-- 1) structural invariants. STRICT configs use the standard ratios-based entry shape the
-- common ore_builder consumes; VARIANT configs (gradient's shape+weight-function entries,
-- joker's special starter area) only need to load and have named entries.
local STRICT_CONFIGS = {
    'vanilla_ores', 'vanilla_ores_gridlocked', 'vanilla_ores_landfill',
    'coal', 'poor_mans_coal_fields_ores', 'scrap',
    'vanilla_ores_stone', 'joker_outer_area',
}
local VARIANT_CONFIGS = { 'vanilla_gradient_ores', 'joker_starter_area' }

for _, config_name in ipairs(STRICT_CONFIGS) do
    local ok, config = pcall(load_config, config_name)
    if not ok then
        check(false, config_name .. ' loads (' .. tostring(config) .. ')')
    else
        local valid = type(config) == 'table' and #config > 0
        for _, entry in ipairs(config) do
            valid = valid and type(entry.name) == 'string'
                and type(entry.tiles) == 'table' and #entry.tiles > 0
                and entry.start ~= nil and entry.weight ~= nil
                and type(entry.ratios) == 'table' and #entry.ratios > 0
            for _, ratio in ipairs(entry.ratios or {}) do
                valid = valid and ratio.resource ~= nil and ratio.weight ~= nil
            end
        end
        check(valid, config_name .. ' is structurally valid (' .. #config .. ' ores)')
    end
end

for _, config_name in ipairs(VARIANT_CONFIGS) do
    local ok, config = pcall(load_config, config_name)
    if not ok then
        check(false, config_name .. ' loads (' .. tostring(config) .. ')')
    else
        local valid = type(config) == 'table' and #config > 0
        for _, entry in ipairs(config) do
            valid = valid and type(entry.name) == 'string'
                and (entry.ratios ~= nil or entry.shape ~= nil)
        end
        check(valid, config_name .. ' loads with named entries (' .. #config .. ' entries)')
    end
end

-- 2) derived configs share their source's tables (one source of truth for the numbers)
local with_stone = load_config('vanilla_ores_stone')
local vanilla = load_config('vanilla_ores')
local vanilla_by_name = {}
for _, ore in ipairs(vanilla) do
    vanilla_by_name[ore.name] = ore
end
check(#with_stone == 4, 'vanilla_ores_stone has 4 ores')
check(rawequal(with_stone[1], vanilla_by_name['iron-ore'])
    and rawequal(with_stone[2], vanilla_by_name['copper-ore'])
    and rawequal(with_stone[3], vanilla_by_name['coal']),
    'vanilla_ores_stone entries 1-3 ARE the vanilla_ores entries')
check(with_stone[4].name == 'stone', 'vanilla_ores_stone entry 4 is stone')

-- 3) the factory: canonical numbers, and fresh tables per call so configs can never
-- share mutable state at runtime
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

local function mix_weights(mix)
    local weights = {}
    for _, pair in ipairs(Factory.mixes[mix]) do
        weights[#weights + 1] = pair[1] .. ':' .. pair[2]
    end
    return table.concat(weights, ' ')
end
check(mix_weights('iron-ore') == 'iron-ore:75 copper-ore:13 stone:7 coal:5'
    and mix_weights('copper-ore') == 'iron-ore:15 copper-ore:70 stone:10 coal:5'
    and mix_weights('coal') == 'iron-ore:18 copper-ore:9 stone:8 coal:65'
    and mix_weights('stone') == 'iron-ore:25 copper-ore:10 stone:60 coal:5',
    'factory mixes carry the canonical weights')

local entry_a = Factory.entry {name = 'iron-ore', start = 1, value = 'v'}
local entry_b = Factory.entry {name = 'iron-ore', start = 1, value = 'v'}
check(not rawequal(entry_a.tiles, entry_b.tiles) and not rawequal(entry_a.ratios, entry_b.ratios),
    'factory builds fresh tiles and ratios tables per call')
check(entry_a.tiles[1] == 'grass-1' and #entry_a.tiles == 4 and entry_a.weight == 1
    and #entry_a.ratios == 4 and entry_a.ratios[1].weight == 75,
    'factory entry has the iron tile set and mix')

local ok_no_value = pcall(Factory.entry, {name = 'iron-ore', start = 1})
check(not ok_no_value, 'factory entry rejects a missing value/make_resource')

-- 4) golden numbers for the source configs, so old maps cannot drift by accident
local function ratio_weights(entry)
    local weights = {}
    for _, ratio in ipairs(entry.ratios) do
        weights[#weights + 1] = tostring(ratio.weight)
    end
    return table.concat(weights, '/')
end
check(ratio_weights(vanilla_by_name['iron-ore']) == '75/13/7/5'
    and ratio_weights(vanilla_by_name['copper-ore']) == '15/70/10/5'
    and ratio_weights(vanilla_by_name['coal']) == '18/9/8/65',
    'vanilla_ores ratio weights unchanged (75/13/7/5, 15/70/10/5, 18/9/8/65)')
check(ratio_weights(with_stone[4]) == '25/10/60/5', 'stone entry ratio weights unchanged')

if failures == 0 then
    print('\nALL PASSED')
else
    print('\n' .. failures .. ' FAILURE(S)')
    os.exit(1)
end
