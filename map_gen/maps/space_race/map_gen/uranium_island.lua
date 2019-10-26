local b = require 'map_gen.shared.builders'
local Event = require 'utils.event'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'

local Game_mode_config = (require 'map_gen.maps.space_race.config').game_mode

local island_1_offset = 0
local island_2_offset = -128
local island_3_offset = 128
local crafters = {}
Global.register(
    {
        crafters = crafters
    },
    function(tbl)
        crafters = tbl.crafters
    end
)

local inf = function()
    return 100000000
end
local uranium_island = b.circle(10)
uranium_island = b.remove_map_gen_resources(uranium_island)
uranium_island = b.remove_map_gen_trees(uranium_island)
uranium_island = b.remove_map_gen_entities_by_filter(uranium_island, {name = {'cliff', 'simple-entity'}})
if not Game_mode_config.king_of_the_hill then
    local uranium_ore = b.resource(b.rectangle(2, 2), 'uranium-ore', inf, true)
    uranium_island = b.apply_entity(uranium_island, uranium_ore)
end

local uranium_island_water = b.change_tile(b.circle(20), true, 'water')
local uranium_island_bridge = b.all({b.any({b.line_x(2), b.line_y(2)}), b.circle(20)})
uranium_island_bridge = b.change_tile(uranium_island_bridge, true, 'water-shallow')
uranium_island_water = b.if_else(uranium_island_bridge, uranium_island_water)

uranium_island = b.if_else(uranium_island, uranium_island_water)

local multiple_uranium_island
if Game_mode_config.king_of_the_hill then
    multiple_uranium_island = b.add(b.translate(uranium_island, 0, island_2_offset), b.translate(uranium_island, 0, island_1_offset))
    multiple_uranium_island = b.add(b.translate(uranium_island, 0, island_3_offset), multiple_uranium_island)
else
    multiple_uranium_island = uranium_island
end

if Game_mode_config.king_of_the_hill then
    local outpost_1 = {
        {name = 'crash-site-lab-broken', position = {0.5, -7.5}},
        {name = 'crash-site-generator', position = {0.5, -3}},
        {name = 'crash-site-assembling-machine-1-broken', position = {-6.5, 0}},
        {name = 'assembling-machine-2', position = {0, 0.5}, recipe = 'low-density-structure'},
        {name = 'crash-site-electric-pole', position = {0.25, -1.48828125}},
        {name = 'crash-site-assembling-machine-1-broken', position = {6.5, 0}},
        {name = 'crash-site-assembling-machine-2-broken', position = {0, 6.5}}
    }

    local outpost_2 = {
        {name = 'crash-site-lab-broken', position = {0.5, -7.5}},
        {name = 'crash-site-generator', position = {0.5, -3}},
        {name = 'crash-site-assembling-machine-1-broken', position = {-6.5, 0}},
        {name = 'crash-site-assembling-machine-2-repaired', position = {0, 0.5}, recipe = 'rocket-control-unit'},
        {name = 'crash-site-electric-pole', position = {0.25, -1.48828125}},
        {name = 'crash-site-assembling-machine-1-broken', position = {6.5, 0}},
        {name = 'crash-site-assembling-machine-2-broken', position = {0, 6.5}}
    }

    local outpost_3 = {
        {name = 'crash-site-generator', position = {x = 0.5, y = -7}, direction = 0},
        {name = 'assembling-machine-3', position = {x = -0.5, y = -3.5}, direction = 4, recipe = 'rocket-fuel'},
        {name = 'crash-site-electric-pole', position = {x = 0.37109375, y = -5.46875}, direction = 0},
        {name = 'storage-tank-remnants', position = {x = -3.5, y = -0.5}, direction = 0},
        {name = 'pipe-to-ground', position = {x = -0.5, y = -1.5}, direction = 0},
        {name = 'crash-site-electric-pole', position = {x = -0.61328125, y = -0.35546875}, direction = 0},
        {name = 'storage-tank-remnants', position = {x = 2.5, y = -0.5}, direction = 0},
        {name = 'oil-refinery', position = {x = -0.5, y = 3.5}, direction = 0},
        {name = 'pipe-to-ground', position = {x = -0.5, y = 0.5}, direction = 4},
        {name = 'offshore-pump', position = {x = -8.5, y = 6.5}, direction = 6},
        {name = 'crash-site-electric-pole', position = {x = 2.35546875, y = 4.5546875}, direction = 0},
        --{name = 'crude-oil', position = {x = 6.5, y = 5.5}, direction = 0, amount = 1000}, -- Not working somehow
        {name = 'pumpjack', position = {x = 6.5, y = 5.5}, direction = 6},
        {name = 'pipe', position = {x = -6.5, y = 6.5}, direction = 0},
        {name = 'pipe', position = {x = -7.5, y = 6.5}, direction = 0},
        {name = 'pipe-to-ground', position = {x = -5.5, y = 6.5}, direction = 6},
        {name = 'pipe-to-ground', position = {x = -2.5, y = 6.5}, direction = 2},
        {name = 'pipe', position = {x = -1.5, y = 6.5}, direction = 0},
        {name = 'pipe', position = {x = 0.5, y = 6.5}, direction = 0},
        {name = 'pipe-to-ground', position = {x = 1.5, y = 6.5}, direction = 6},
        {name = 'pipe-to-ground', position = {x = 4.5, y = 6.5}, direction = 2},
        {name = 'crash-site-electric-pole', position = {x = 6.51171875, y = 7.5546875}, direction = 0}
    }

    local function register_crafter(entity)
        table.insert(crafters, entity)
    end

    local function lock_entity(e)
        e.destructible = false
        e.minable = false
        e.operable = false
        e.rotatable = false
    end

    Event.on_init(
        function()
            local surface = RS.get_surface()
            for k, entity in pairs(outpost_1) do
                entity.position[2] = entity.position[2] + island_1_offset
                entity.force = 'neutral'
                local e = surface.create_entity(entity)
                lock_entity(e)
                if entity.recipe then
                    e.set_recipe('low-density-structure')
                    e.recipe_locked = true
                    register_crafter(e)
                end
            end
            for k, entity in pairs(outpost_2) do
                entity.position[2] = entity.position[2] + island_2_offset
                entity.force = 'neutral'
                local e = surface.create_entity(entity)
                lock_entity(e)
                if entity.recipe then
                    e.set_recipe('rocket-control-unit')
                    e.recipe_locked = true
                    register_crafter(e)
                end
            end
            for k, entity in pairs(outpost_3) do
                entity.position.y = entity.position.y + island_3_offset
                entity.force = 'neutral'
                local e = surface.create_entity(entity)
                if not entity.amount then
                    lock_entity(e)
                end
                if entity.recipe then
                    e.set_recipe('rocket-fuel')
                    e.recipe_locked = true
                    e.direction = defines.direction.south
                    register_crafter(e)
                end
                if entity.name == 'oil-refinery' then
                    e.set_recipe('advanced-oil-processing')
                    e.recipe_locked = true
                end
            end
        end
    )

    Event.on_nth_tick(
        600,
        function()
            if remote.call('space-race', 'get_game_status') then
                for _, crafter in pairs(crafters) do
                    local item = crafter.get_recipe().products[1].name
                    crafter.get_output_inventory().insert({name = item, count = 1})
                end
            end
        end
    )
end

return multiple_uranium_island
