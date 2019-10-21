--Hilbert Water Trap Map, by SimonFlapse, based on Hilbert Sand Trap by Jayefuu, R. Nukem, and grilledham

local b = require 'map_gen.shared.builders'
local degrees = require 'utils.math'.degrees
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local redmew_config = global.config
--https://www.fractalus.com/kerry/tutorials/hilbert/hilbert-tutorial.html
-- Setup the scenario map information because everyone gets upset if you don't
local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name("Hilbert's Sand Trap")
ScenarioInfo.set_map_description("You have crash landed in the middle of Hilbert's Labyrinth! Surrounded by quicksand and biters you must survive long enough to launch a rocket.")
ScenarioInfo.set_map_extra_info(
    'Only the native grasses are suitable to build on. Ores and trees have sunk into the sand, but biters have adapted to live happily in the barren landscape. Some even speak of a Hydra living deep within the desert. \n\n Map created by R. Nukem and Jayefuu, with help from grilledham and the rest of the Redmew admin team.'
)
--enable Hydra
local hail_hydra = redmew_config.hail_hydra
hail_hydra.enabled = true
--tweak hydra settings. Default settings are WAY too hard (circa 2019-02-22 hydra)
--This section will need updated in the future pending changes to how hydra is configured (PR #795)
hail_hydra.hydras = {
    -- spitters
    ['small-spitter'] = {['small-worm-turret'] = 0.05}, --default 0.2
    ['medium-spitter'] = {['medium-worm-turret'] = 0.05}, --defualt 0.2
    ['big-spitter'] = {['big-worm-turret'] = 0.05}, --defualt 0.2
    ['behemoth-spitter'] = {['big-worm-turret'] = 0.2}, --default 0.4
    -- biters
    ['medium-biter'] = {['small-biter'] = 0.4}, --default 1.2
    ['big-biter'] = {['medium-biter'] = 0.4},
     --default 1.2
    ['behemoth-biter'] = {['big-biter'] = 0.4},
     --default 1.2
    -- worms
    ['small-worm-turret'] = {['small-biter'] = .75},
     --defualt 2.5
    ['medium-worm-turret'] = {['small-biter'] = .75, ['medium-biter'] = 0.3}, --default 2.5, .6
    ['big-worm-turret'] = {['small-biter'] = 2.0, ['medium-biter'] = 1.0, ['big-biter'] = 0.5} --defualt 3.8, 1.3, 1.1
}
hail_hydra.evolution_scale = .7

local market_config = redmew_config.market
market_config.standard_market_location = {0, -7} -- Some how the market gets removed
market_config.delay = 5 -- delays spawning the market by 5 ticks

-- define map settings

--Ore settings. I feel very-high frequency is required to keep the sand from eating all the ores
-- Richness and size can be changed to tweak balance a bit.
local ore_settings = {
    autoplace_controls = {
        coal = {
            frequency = 'very-high',
            richness = 'normal',
            size = 'normal'
        },
        ['copper-ore'] = {
            frequency = 'very-high',
            richness = 'normal',
            size = 'normal'
        },
        ['crude-oil'] = {
            frequency = 'very-high',
            richness = 'normal',
            size = 'normal'
        },
        ['iron-ore'] = {
            frequency = 'very-high',
            richness = 'normal',
            size = 'normal'
        },
        stone = {
            frequency = 'very-high',
            richness = 'normal',
            size = 'normal'
        },
        ['uranium-ore'] = {
            frequency = 'very-high',
            richness = 'very-low',
            size = 'very-small'
        }
    }
}
-- Another section that can be used for balance. Setting richness above normal is not recommended
local tree_settings = {
    autoplace_controls = {
        trees = {
            frequency = 'very-high',
            richness = 'normal',
            size = 'normal'
        }
    }
}

-- This seems to be a decent balance between small pools of water and not blocking entire sections
-- of the maze near spawn by lakes
local water_settings = {
    terrain_segmentation = 'high',
    water = 'low'
}
--Set map settings
RS.set_map_gen_settings(
    {
        MGSP.cliff_none,
        MGSP.grass_only,
        MGSP.enable_water,
        MGSP.enemy_very_high,
        MGSP.starting_area_very_low,
        ore_settings,
        tree_settings,
        water_settings
    }
)

--start hilbert design. Note: The following code does contain bugs. Jayefuu and R.Nukem are aware of
--this and will look into fixing it at a later date. For now keep hilbert_levels = 2
--The following values can be changed to adjust the width of the maze and sand
local block_width = 6
local block_length = 16
local scale_factor = 11
local hilbert_levels = 2 -- do not change unless the algorithm has been fixed

local line_1 = b.translate(b.rectangle(block_width, block_length), -5, 0) --adjust size of rectangle to change maze width
local tier_1 =
    b.any {
    line_1,
    b.rotate(line_1, degrees(-90)),
    b.rotate(line_1, degrees(-180))
}
local pattern = tier_1
local var = 20
for i = 1, hilbert_levels do
    -- do the rotation stuff
    pattern =
        b.any {
        pattern,
        b.translate(b.flip_x(pattern), i * var, 0),
        b.translate(b.rotate(pattern, degrees(90)), i * var, i * var),
        b.translate(b.rotate(pattern, degrees(-90)), 0, i * var)
    }
    -- translate the pattern so that the connecting pieces are easier to add
    pattern = b.translate(pattern, -0.5 * i * var, -0.5 * i * var)

    -- add the 3 connecting pieces
    pattern =
        b.any {
        pattern,
        b.translate(line_1, (10 * (i - 1) + (10 * i)) * -1, 0),
        b.translate(b.rotate(line_1, degrees(180)), (10 * (i - 1) + (10 * i)), 0),
        b.rotate(line_1, degrees(-90))
        --b.translate(line_1,-10,0)
    }
end
pattern =
    b.any {
    pattern,
    b.translate(b.rotate(line_1, degrees(90)), -40, 30),
    b.translate(b.rotate(line_1, degrees(90)), 40, 30)
}
-- Tile map in X direction
local function ribbon(_, y)
    local abs_y = math.abs(y)
    return (abs_y < 40)
end

ribbon = b.change_tile(ribbon, true, 'water-shallow')
ribbon = b.remove_map_gen_decoratives_by_filter(ribbon)
ribbon = b.remove_map_gen_resources(ribbon)
ribbon = b.remove_map_gen_trees(ribbon)
ribbon = b.translate(ribbon, 0, 6)
pattern = b.translate(pattern, 0, 5)
local hilbert = b.single_x_pattern(pattern, 80)
local map = b.any {hilbert, ribbon}
--Change this to scale map

map = b.scale(map, scale_factor, scale_factor)
-- make starting area
local start_region = b.rectangle(block_length * scale_factor, block_width * scale_factor)
map = b.subtract(map, start_region)
start_region = b.change_map_gen_collision_tile(start_region, 'water-tile', 'landfill')
start_region = b.remove_map_gen_resources(start_region)
local start_water = b.change_tile(b.circle(5), true, 'water')
map = b.any {start_water, start_region, map}
--make starting ores
local value = b.manhattan_value
local ore_shape = b.scale(b.circle(30), 0.15)
local start_ore = b.circle(30)
local start_iron = b.resource(start_ore, 'iron-ore', value(1000, 0))
local start_copper = b.resource(start_ore, 'copper-ore', value(750, 0))
local start_coal = b.resource(start_ore, 'coal', value(500, 0))
local start_stone = b.resource(start_ore, 'stone', value(500, 0))
start_ore = b.segment_pattern({start_coal, start_stone, start_copper, start_iron})
ore_shape = b.choose(b.circle(30), start_ore, ore_shape)

--apply starting ores to map
map = b.apply_entity(map, ore_shape)
--shift spawn so player doesn't die to start water
map = b.translate(map, 0, 30)

return map
