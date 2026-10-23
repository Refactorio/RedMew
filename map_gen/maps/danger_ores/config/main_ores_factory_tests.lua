-- In-game tests for the Danger Ores ore configs and the factory that builds them. These run
-- under _DEBUG via /test-runner, and in CI, whenever main_ores_factory.lua is loaded, i.e. on
-- most Danger Ores maps. None of them touch the map: they run in game so the configs are built
-- with the real builders, on Factorio's own Lua.
--
-- An ore's richness is a resource function, as the map uses it: called at a position, it gives
-- the ore's name and amount there. Curves are compared by what they give at a few positions.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local b = require 'map_gen.shared.builders'
local Factory = require 'map_gen.maps.danger_ores.config.main_ores_factory'

-- STRICT configs use the standard ratios-based entry shape the common ore_builder consumes;
-- VARIANT configs (gradient's shape+weight-function entries, joker's special starter area) only
-- need to load and have named entries.
local STRICT_CONFIGS = {
    'vanilla_ores', 'vanilla_ores_gridlocked', 'vanilla_ores_landfill',
    'coal', 'poor_mans_coal_fields_ores', 'scrap',
    'vanilla_ores_stone', 'joker_outer_area',
}
local VARIANT_CONFIGS = {'vanilla_gradient_ores', 'joker_starter_area'}

-- every config is loaded here, as require only works while the scenario loads; a config that
-- fails to load is reported by the test instead
local configs, load_errors = {}, {}
for _, list in pairs({STRICT_CONFIGS, VARIANT_CONFIGS}) do
    for _, name in pairs(list) do
        local ok, config = pcall(require, 'map_gen.maps.danger_ores.config.' .. name)
        if ok then
            configs[name] = config
        else
            load_errors[name] = tostring(config)
        end
    end
end

local POSITIONS = {{0, 0}, {100, 0}, {-300, 250}}

local function resource_at(resource, x, y)
    return resource(x, y, {x = x, y = y})
end

local function name_of(resource)
    return resource_at(resource, 0, 0).name
end

local function amount_of(resource)
    return resource_at(resource, 0, 0).amount
end

local function assert_amounts(resource, curve, what)
    for _, p in pairs(POSITIONS) do
        local x, y = p[1], p[2]
        Assert.equal(curve(x, y), resource_at(resource, x, y).amount, what .. ' at ' .. x .. ',' .. y)
    end
end

local function assert_curve(actual, curve, what)
    Assert.equal('function', type(actual), what .. ' is not a curve')
    for _, p in pairs(POSITIONS) do
        local x, y = p[1], p[2]
        Assert.equal(curve(x, y), actual(x, y), what .. ' at ' .. x .. ',' .. y)
    end
end

-- "75/13/7/5": the weights of an entry's ore mix
local function ratio_weights(entry)
    local weights = {}
    for _, ratio in ipairs(entry.ratios) do
        weights[#weights + 1] = tostring(ratio.weight)
    end
    return table.concat(weights, '/')
end

local function by_name(config)
    local entries = {}
    for _, entry in ipairs(config) do
        entries[entry.name] = entry
    end
    return entries
end

-- curves that give one amount everywhere, so scaled results are easy to read
local function flat(amount)
    return function()
        return amount
    end
end

Declare.module(
    {'map_gen', 'danger ores', 'ore configs'},
    function()
        Declare.test(
            'every ore config loads with valid entries',
            function()
                for name, err in pairs(load_errors) do
                    error(name .. ' does not load: ' .. err)
                end

                for _, name in ipairs(STRICT_CONFIGS) do
                    local config = configs[name]
                    Assert.is_true(type(config) == 'table' and #config > 0, name .. ' has no entries')
                    for i, entry in ipairs(config) do
                        local what = name .. ' entry ' .. i
                        Assert.equal('string', type(entry.name), what .. ' name')
                        Assert.is_true(type(entry.tiles) == 'table' and #entry.tiles > 0, what .. ' has no tiles')
                        Assert.is_true(entry.start ~= nil and entry.weight ~= nil, what .. ' has no start or weight')
                        Assert.is_true(type(entry.ratios) == 'table' and #entry.ratios > 0, what .. ' has no ratios')
                        for _, ratio in ipairs(entry.ratios) do
                            Assert.is_true(ratio.resource ~= nil and ratio.weight ~= nil, what .. ' has a ratio without a resource or weight')
                        end
                    end
                end

                for _, name in ipairs(VARIANT_CONFIGS) do
                    local config = configs[name]
                    Assert.is_true(type(config) == 'table' and #config > 0, name .. ' has no entries')
                    for i, entry in ipairs(config) do
                        Assert.equal('string', type(entry.name), name .. ' entry ' .. i .. ' name')
                        Assert.is_true(entry.ratios ~= nil or entry.shape ~= nil, name .. ' entry ' .. i .. ' has neither ratios nor a shape')
                    end
                end
            end
        )

        -- golden numbers, so old maps cannot drift by accident
        Declare.test(
            'the source configs keep their ore mixes, and the stone one adds stone to vanilla',
            function()
                local vanilla, with_stone = configs.vanilla_ores, configs.vanilla_ores_stone
                local vanilla_by_name = by_name(vanilla)
                Assert.equal(3, #vanilla, 'vanilla_ores sectors')
                Assert.equal('75/13/7/5', ratio_weights(vanilla_by_name['iron-ore']), 'vanilla_ores iron mix')
                Assert.equal('15/70/10/5', ratio_weights(vanilla_by_name['copper-ore']), 'vanilla_ores copper mix')
                Assert.equal('18/9/8/65', ratio_weights(vanilla_by_name['coal']), 'vanilla_ores coal mix')

                Assert.equal(4, #with_stone, 'vanilla_ores_stone ores')
                for i = 1, 3 do
                    local a, v = with_stone[i], vanilla[i]
                    Assert.equal(v.name, a.name, 'vanilla_ores_stone sector ' .. i)
                    Assert.equal(#v.ratios, #a.ratios, 'ratios in vanilla_ores_stone sector ' .. i)
                    for r = 1, #a.ratios do
                        Assert.equal(v.ratios[r].weight, a.ratios[r].weight, 'weight of ratio ' .. r .. ' in vanilla_ores_stone sector ' .. i)
                        Assert.equal(name_of(v.ratios[r].resource), name_of(a.ratios[r].resource), 'ore of ratio ' .. r .. ' in vanilla_ores_stone sector ' .. i)
                    end
                end
                Assert.equal('stone', with_stone[4].name, 'vanilla_ores_stone entry 4')
                Assert.equal('25/10/60/5', ratio_weights(with_stone[4]), 'vanilla_ores_stone stone mix')
            end
        )

        Declare.test(
            'factory entries carry the canonical mixes, in fresh tables',
            function()
                local function mix_weights(mix)
                    local weights = {}
                    for _, pair in ipairs(Factory.mixes[mix]) do
                        weights[#weights + 1] = pair[1] .. ':' .. pair[2]
                    end
                    return table.concat(weights, ' ')
                end
                Assert.equal('iron-ore:75 copper-ore:13 stone:7 coal:5', mix_weights('iron-ore'), 'iron mix')
                Assert.equal('iron-ore:15 copper-ore:70 stone:10 coal:5', mix_weights('copper-ore'), 'copper mix')
                Assert.equal('iron-ore:18 copper-ore:9 stone:8 coal:65', mix_weights('coal'), 'coal mix')
                Assert.equal('iron-ore:25 copper-ore:10 stone:60 coal:5', mix_weights('stone'), 'stone mix')

                -- configs must never share mutable state at runtime
                local value = flat(10)
                local entry_a = Factory.entry {name = 'iron-ore', start = 1, value = value}
                local entry_b = Factory.entry {name = 'iron-ore', start = 1, value = value}
                Assert.is_true(not rawequal(entry_a.tiles, entry_b.tiles) and not rawequal(entry_a.ratios, entry_b.ratios),
                    'two entries share their tiles or ratios table')
                Assert.is_true(entry_a.tiles[1] == 'grass-1' and #entry_a.tiles == 4, 'the iron entry does not have the iron tile set')
                Assert.equal(1, entry_a.weight, 'iron entry weight')
                Assert.equal('75/13/7/5', ratio_weights(entry_a), 'iron entry mix')

                Assert.is_true(not pcall(Factory.entry, {name = 'iron-ore', start = 1}), 'an entry without a value or make_resource was built')

                local d1, d2 = Factory.default(), Factory.default()
                Assert.is_true(not rawequal(d1, d2) and not rawequal(d1[1], d2[1]) and not rawequal(d1[1].ratios, d2[1].ratios),
                    'two fluent configs share tables')
            end
        )

        Declare.test(
            'the fluent API builds and reshapes sectors',
            function()
                local fl = Factory.default()
                Assert.equal(3, #fl, 'sectors in Factory.default()')
                Assert.is_true(fl[1].name == 'copper-ore' and fl[2].name == 'coal' and fl[3].name == 'iron-ore',
                    'Factory.default() is not copper, coal, iron')
                Assert.is_true(rawequal(fl:add_ore('stone'), fl), 'add_ore does not chain on the same object')
                Assert.is_true(#fl == 4 and fl[4].name == 'stone' and fl[4].tiles[1] == 'sand-1', 'add_ore did not append the stone sector')

                for i, entry in ipairs(Factory.default():change_tiles('landfill')) do
                    Assert.is_true(#entry.tiles == 1 and entry.tiles[1] == 'landfill', 'change_tiles did not reskin sector ' .. i)
                end
                local snow = Factory.default():change_tiles({'grass-2', 'grass-3', 'grass-4'}, 'iron-ore')
                Assert.is_true(snow[3].tiles[1] == 'grass-2' and #snow[3].tiles == 3, 'change_tiles with an ore name did not reskin that sector')
                Assert.equal('red-desert-0', snow[1].tiles[1], 'change_tiles with an ore name reskinned another sector')

                local weighted = Factory.default():sector_weights {coal = 8}
                Assert.is_true(weighted[2].weight == 8 and weighted[1].weight == 1, 'sector_weights did not set the weights by name')

                local modded = Factory.blank():add_ore('omnite')
                Assert.is_true(#modded == 1 and modded[1].tiles == nil and #modded[1].ratios == 1, 'blank():add_ore did not give a tile-less single-ore sector')
                Assert.equal('omnite', name_of(modded[1].ratios[1].resource), 'blank():add_ore ore')
                Assert.equal(1, modded[1].ratios[1].weight, 'blank():add_ore weight')

                local all_coal = Factory.default():change_mix {{'coal', 1}}
                for _, i in pairs({1, 3}) do
                    Assert.equal(1, #all_coal[i].ratios, 'ratios in sector ' .. i .. ' after change_mix')
                    Assert.equal('coal', name_of(all_coal[i].ratios[1].resource), 'ore in sector ' .. i .. ' after change_mix')
                end
                local iron_pure = Factory.default():change_mix({{'iron-ore', 1}}, 'iron-ore')
                Assert.is_true(#iron_pure[3].ratios == 1 and #iron_pure[1].ratios == 4, 'change_mix with an ore name did not rewrite only that sector')

                local trimmed = Factory.default():remove_ore('coal')
                Assert.is_true(#trimmed == 2 and trimmed[1].name == 'copper-ore' and trimmed[2].name == 'iron-ore', 'remove_ore did not drop coal')

                local updated = Factory.default():update_ore('coal', {weight = 5, mix = {{'coal', 1}}})
                Assert.is_true(updated[2].weight == 5 and #updated[2].ratios == 1, 'update_ore did not patch the coal sector')
                Assert.equal('coal', name_of(updated[2].ratios[1].resource), 'ore of the updated coal sector')

                local no_dark = Factory.default():remove_tile('grass-4')
                Assert.is_true(#no_dark[3].tiles == 3 and no_dark[3].tiles[3] == 'grass-3' and #no_dark[1].tiles == 4,
                    'remove_tile did not drop the tile from only the sector that has it')

                local extra_tile = Factory.default():add_tile('snow-0', 'coal')
                Assert.is_true(extra_tile[2].tiles[8] == 'snow-0' and #extra_tile[1].tiles == 4, 'add_tile did not append to only the coal sector')
            end
        )

        Declare.test(
            'richness and start value shorthands become the curves they describe',
            function()
                local rich = Factory.default():richness {base = 50, mult = 0.003, pow = 2.25}:start_value {base = 50, mult = 0.75}
                assert_amounts(rich[1].ratios[1].resource, b.exponential_value(50, 0.003, 2.25), 'richness')
                assert_curve(rich[1].start, b.euclidean_value(50, 0.75), 'start value')

                -- the second one positional: the fallback still works
                local low_coal = Factory.default():richness {mult = 0.5, pow = 1.1}:richness({0, 0.9, 1.9}, 'coal')
                assert_amounts(low_coal[2].ratios[1].resource, b.exponential_value(0, 0.9, 1.9), 'coal richness')
                assert_amounts(low_coal[1].ratios[1].resource, b.exponential_value(0, 0.5, 1.1), 'copper richness')

                local flat_iron = Factory.default():start_value(7, 'iron-ore')
                Assert.equal(7, flat_iron[3].start, 'iron start value')
                Assert.is_true(flat_iron[1].start ~= 7, 'start_value with an ore name changed another sector')
            end
        )

        Declare.test(
            'scale_richness scales the richness and start curves',
            function()
                local scaled = Factory.blank()
                    :add_ore('scrap', {mix = {{'scrap', 100}}})
                    :richness(flat(100))
                    :start_value(flat(40))
                    :scale_richness(0.25)
                Assert.equal(25, amount_of(scaled[1].ratios[1].resource), 'scaled richness')
                Assert.equal(10, scaled[1].start(), 'scaled start value')

                local half_coal = Factory.default()
                    :richness(flat(100))
                    :start_value(50)
                    :scale_richness(0.5, 'coal')
                Assert.equal(50, amount_of(half_coal[2].ratios[1].resource), 'coal richness scaled by name')
                Assert.equal(25, half_coal[2].start, 'coal start value scaled by name')
                Assert.equal(100, amount_of(half_coal[1].ratios[1].resource), 'copper richness, not named')
                Assert.equal(50, half_coal[1].start, 'copper start value, not named')

                local compounded = Factory.blank()
                    :add_ore('omnite')
                    :richness(flat(100))
                    :start_value(8)
                    :scale_richness(0.5)
                    :scale_richness(0.5)
                Assert.equal(25, amount_of(compounded[1].ratios[1].resource), 'richness scaled twice')
                Assert.equal(2, compounded[1].start, 'start value scaled twice')

                local scaled_then_added = Factory.blank()
                    :richness(flat(100))
                    :start_value(flat(40))
                    :scale_richness(0.25)
                    :add_ore('scrap', {mix = {{'scrap', 100}}})
                Assert.equal(25, amount_of(scaled_then_added[1].ratios[1].resource), 'richness of a sector added after scaling')
                Assert.equal(10, scaled_then_added[1].start(), 'start value of a sector added after scaling')
            end
        )

        Declare.test(
            'patches are built, scaled and carried over',
            function()
                local stone = Factory.patches():add_patch('stone', {scale = 1 / 32, threshold = 0.6, richness = flat(100)})
                Assert.is_true(#stone == 1 and stone[1].scale == 1 / 32 and stone[1].threshold == 0.6, 'add_patch did not keep the size and rarity')
                Assert.equal('stone', name_of(stone[1].resource), 'patch ore')
                Assert.equal(100, amount_of(stone[1].resource), 'patch richness')

                stone:scale {richness = 0.25, size = 2}
                Assert.equal(1 / 64, stone[1].scale, 'patch scale after growing it')
                Assert.equal(25, amount_of(stone[1].resource), 'patch richness after scaling it')

                local canonical = Factory.patches():add_patch('iron-ore')
                Assert.is_true(canonical[1].scale == 1 / 24 and canonical[1].threshold == 0.5, 'add_patch does not default to the canonical size and rarity')
                assert_amounts(canonical[1].resource, b.exponential_value(0, 1.4, 1.45), 'default patch richness')

                local source = {
                    {scale = 1 / 24, threshold = 0.5, resource = function()
                        return {name = 'iron-ore', amount = 100}
                    end},
                    {scale = 1 / 24, threshold = 0.5, resource = function()
                        return nil
                    end}
                }
                local wrapped = Factory.patches(source):scale {richness = 0.5, size = 2}
                Assert.equal(1 / 48, wrapped[1].scale, 'carried over patch scale')
                Assert.equal(50, amount_of(wrapped[1].resource), 'carried over patch richness')
                Assert.is_nil(resource_at(wrapped[2].resource, 0, 0), 'a carried over empty patch result')
                Assert.equal(1 / 24, source[1].scale, 'the original patch scale was changed')
                Assert.equal(100, amount_of(source[1].resource), 'the original patch richness was changed')

                local compounded = Factory.patches(source):scale {richness = 0.5}:scale {richness = 0.5}
                Assert.equal(25, amount_of(compounded[1].resource), 'patch richness scaled twice')

                local late = Factory.patches():scale {richness = 0.5}:add_patch('stone', {richness = flat(100)})
                Assert.equal(50, amount_of(late[1].resource), 'richness of a patch added after scaling')
            end
        )
    end
)
