-- Standalone unit tests for the danger-ores ore configs.
-- Run from the repo root:  lua map_gen/maps/danger_ores/config/ore_configs.test.lua
package.path = './?.lua;' .. package.path

-- stub Factorio's built-in util module (utils.table pulls table.deepcopy from it)
package.preload['util'] = function()
    local function deepcopy(object)
        if type(object) ~= 'table' then
            return object
        end
        local copy = {}
        for k, v in pairs(object) do
            copy[deepcopy(k)] = deepcopy(v)
        end
        return setmetatable(copy, getmetatable(object))
    end
    table.deepcopy = deepcopy -- luacheck: ignore 122
    table.compare = function(a, b) -- luacheck: ignore 122
        return a == b
    end
    util = {merge = function(tables) return tables[1] end} -- luacheck: globals util
    return util
end

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

-- 2) derived configs carry the same canonical numbers as their source
local with_stone = load_config('vanilla_ores_stone')
local vanilla = load_config('vanilla_ores')
local vanilla_by_name = {}
for _, ore in ipairs(vanilla) do
    vanilla_by_name[ore.name] = ore
end
check(#vanilla == 3, 'vanilla_ores has 3 sectors')
check(#with_stone == 4, 'vanilla_ores_stone has 4 ores')
local same_sectors = true
for i = 1, 3 do
    local a, v = with_stone[i], vanilla[i]
    same_sectors = same_sectors and a.name == v.name and #a.ratios == #v.ratios
    for r = 1, #a.ratios do
        same_sectors = same_sectors and a.ratios[r].weight == v.ratios[r].weight
            and a.ratios[r].resource.name == v.ratios[r].resource.name
    end
end
check(same_sectors, 'vanilla_ores_stone sectors 1-3 match vanilla_ores')
check(with_stone[4].name == 'stone', 'vanilla_ores_stone entry 4 is stone')
check(not rawequal(load_config('vanilla_ores'), nil) and true, 'vanilla_ores loads')

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

-- 4) the fluent API
local fl = Factory.default()
check(#fl == 3 and fl[1].name == 'copper-ore' and fl[2].name == 'coal' and fl[3].name == 'iron-ore',
    'Factory.default() is the canonical 3-sector config')
check(rawequal(fl:add_ore('stone'), fl) and #fl == 4 and fl[4].name == 'stone'
    and fl[4].tiles[1] == 'sand-1',
    'add_ore chains on the same object and appends the canonical stone sector')

local landfill_fl = Factory.default():change_tiles('landfill')
local all_landfill = true
for _, entry in ipairs(landfill_fl) do
    all_landfill = all_landfill and #entry.tiles == 1 and entry.tiles[1] == 'landfill'
end
check(all_landfill, 'change_tiles reskins every sector')

local snow = Factory.default():change_tiles({'grass-2', 'grass-3', 'grass-4'}, 'iron-ore')
check(snow[3].tiles[1] == 'grass-2' and #snow[3].tiles == 3 and snow[1].tiles[1] == 'red-desert-0',
    'change_tiles with an ore name reskins only that sector')

local rich = Factory.default():richness{base = 50, mult = 0.003, pow = 2.25}:start_value{base = 50, mult = 0.75}
check(rich[1].ratios[1].resource.value == 'exp(50,0.003,2.25)' and rich[1].start == 'euclid(50,0.75)',
    'richness/start_value shorthands rebuild every ratio')

local weighted = Factory.default():sector_weights{coal = 8}
check(weighted[2].weight == 8 and weighted[1].weight == 1, 'sector_weights sets weights by name')

local modded = Factory.blank():add_ore('omnite')
check(#modded == 1 and modded[1].tiles == nil and #modded[1].ratios == 1
    and modded[1].ratios[1].resource.name == 'omnite' and modded[1].ratios[1].weight == 1,
    'blank():add_ore gives unknown ores a pure self-mix and no tiles')

local all_coal = Factory.default():change_mix{{'coal', 1}}
check(#all_coal[1].ratios == 1 and all_coal[1].ratios[1].resource.name == 'coal'
    and #all_coal[3].ratios == 1 and all_coal[3].ratios[1].resource.name == 'coal',
    'change_mix rewrites every sector')

local iron_pure = Factory.default():change_mix({{'iron-ore', 1}}, 'iron-ore')
check(#iron_pure[3].ratios == 1 and #iron_pure[1].ratios == 4,
    'change_mix with an ore name rewrites only that sector')

local trimmed = Factory.default():remove_ore('coal')
check(#trimmed == 2 and trimmed[1].name == 'copper-ore' and trimmed[2].name == 'iron-ore',
    'remove_ore drops the named sector')

local updated = Factory.default():update_ore('coal', {weight = 5, mix = {{'coal', 1}}})
check(updated[2].weight == 5 and #updated[2].ratios == 1 and updated[2].ratios[1].resource.name == 'coal',
    'update_ore patches a sector in place')

local no_dark = Factory.default():remove_tile('grass-4')
check(#no_dark[3].tiles == 3 and no_dark[3].tiles[3] == 'grass-3' and #no_dark[1].tiles == 4,
    'remove_tile drops a tile from the sector that has it')

local extra_tile = Factory.default():add_tile('snow-0', 'coal')
check(extra_tile[2].tiles[8] == 'snow-0' and #extra_tile[1].tiles == 4,
    'add_tile appends only to the named sector')

local low_coal = Factory.default():richness{mult = 0.5, pow = 1.1}:richness({0, 0.9, 1.9}, 'coal') -- second one positional: fallback still works
check(low_coal[2].ratios[1].resource.value == 'exp(0,0.9,1.9)'
    and low_coal[1].ratios[1].resource.value == 'exp(0,0.5,1.1)',
    'richness with an ore name overrides one sector, default covers the rest')

local flat_iron = Factory.default():start_value(7, 'iron-ore')
check(flat_iron[3].start == 7 and flat_iron[1].start ~= 7,
    'start_value with an ore name overrides one sector')

local d1, d2 = Factory.default(), Factory.default()
check(not rawequal(d1, d2) and not rawequal(d1[1], d2[1]) and not rawequal(d1[1].ratios, d2[1].ratios),
    'every fluent config is built from fresh tables')

-- function curves so the scaled results stay callable under the stubbed builders
local function flat(amount)
    return function()
        return amount
    end
end

local function test_scale_richness()
    local scaled = Factory.blank()
        :add_ore('scrap', {mix = {{'scrap', 100}}})
        :richness(flat(100))
        :start_value(flat(40))
        :scale_richness(0.25)
    check(scaled[1].ratios[1].resource.value() == 25 and scaled[1].start() == 10,
        'scale_richness scales the richness and start curves')

    local half_coal = Factory.default()
        :richness(flat(100))
        :start_value(50)
        :scale_richness(0.5, 'coal')
    check(half_coal[2].ratios[1].resource.value() == 50 and half_coal[2].start == 25
        and half_coal[1].ratios[1].resource.value() == 100 and half_coal[1].start == 50,
        'scale_richness with an ore name scales only that sector')

    local compounded = Factory.blank()
        :add_ore('omnite')
        :richness(flat(100))
        :start_value(8)
        :scale_richness(0.5)
        :scale_richness(0.5)
    check(compounded[1].ratios[1].resource.value() == 25 and compounded[1].start == 2,
        'scale_richness compounds when applied twice')

    local scaled_then_added = Factory.blank()
        :richness(flat(100))
        :start_value(flat(40))
        :scale_richness(0.25)
        :add_ore('scrap', {mix = {{'scrap', 100}}})
    check(scaled_then_added[1].ratios[1].resource.value() == 25 and scaled_then_added[1].start() == 10,
        'sectors added after scale_richness still get the scaled defaults')
end
test_scale_richness()

local function test_patches()
    local stone = Factory.patches()
        :add_patch('stone', {scale = 1 / 32, threshold = 0.6, richness = flat(100)})
    check(#stone == 1 and stone[1].scale == 1 / 32 and stone[1].threshold == 0.6
        and stone[1].resource.name == 'stone' and stone[1].resource.value() == 100,
        'patches():add_patch builds a pure resource patch entry')

    stone:scale{richness = 0.25, size = 2}
    check(stone[1].scale == 1 / 64 and stone[1].resource.value() == 25,
        'patches scale multiplies richness and grows the patch size')

    local canonical = Factory.patches():add_patch('iron-ore')
    check(canonical[1].scale == 1 / 24 and canonical[1].threshold == 0.5
        and canonical[1].resource.value == 'exp(0,1.4,1.45)',
        'add_patch defaults to the canonical patch size, rarity and curve')

    local source = {
        {scale = 1 / 24, threshold = 0.5, resource = function()
            return {name = 'iron-ore', amount = 100}
        end},
        {scale = 1 / 24, threshold = 0.5, resource = function()
            return nil
        end}
    }
    local wrapped = Factory.patches(source):scale{richness = 0.5, size = 2}
    check(wrapped[1].scale == 1 / 48 and wrapped[1].resource(0, 0, {}).amount == 50,
        'patches(source) carries over an existing config and scales it')
    check(wrapped[2].resource(0, 0, {}) == nil,
        'patches(source) preserves empty resource results')
    check(source[1].scale == 1 / 24 and source[1].resource(0, 0, {}).amount == 100,
        'patches(source) does not modify the original config')

    local compounded = Factory.patches(source):scale{richness = 0.5}:scale{richness = 0.5}
    check(compounded[1].resource(0, 0, {}).amount == 25,
        'patches scale compounds when applied twice')

    local late = Factory.patches():scale{richness = 0.5}:add_patch('stone', {richness = flat(100)})
    check(late[1].resource.value() == 50,
        'patches added after scale still get the scale applied')
end
test_patches()

-- 5) golden numbers for the source configs, so old maps cannot drift by accident
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
