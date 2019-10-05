local floor = math.floor
local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'
local Token = require 'utils.token'
local Color = require 'resources.color_presets'

local redmew_config = global.config

-- Needed because refined hazard concrete is needed and must not be changed by this module
redmew_config.paint.enabled = false

local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Concrete Jungle')
ScenarioInfo.set_map_description([[
Extensive underground mining has resulted in brittle soil.
New regulations requires heavy objects to being placed on top of,
proper materials to support the ground!
]])

-- Tiers of tiles definition (tier 0 is default)
local tile_tiers = {
    ['stone-path'] = 1,
    ['concrete'] = 2,
    ['refined-concrete'] = 3,
    ['hazard-concrete-right'] = 2,
    ['hazard-concrete-left'] = 2,
    ['refined-hazard-concrete-right'] = 3,
    ['refined-hazard-concrete-left'] = 3
}

--- Items explicitly allowed everywhere (tier 0 and up)
--- The RestrictEntities module auto skips all checks for these entities
--- They do not trigger set_keep_alive_callback or the on_pre_restricted_entity_destroyed event
RestrictEntities.add_allowed(
    {
        'transport-belt',
        'fast-transport-belt',
        'express-transport-belt',
        'underground-belt',
        'fast-underground-belt',
        'express-underground-belt',
        'small-electric-pole',
        'burner-mining-drill',
        'pumpjack',
        'car',
        'tank',
        'pipe',
        'pipe-to-ground',
        'offshore-pump'
    }
)

-- Items only allowed on tiles of tier 2 or higher (tier 1 is the default)
local entity_tiers = {
    -- Tier 2
    ['oil-refinery'] = 2,
    ['chemical-plant'] = 2,
    ['storage-tank'] = 2,
    ['straight-rail'] = 2,
    ['curved-rail'] = 2,
    ['train-stop'] = 2,
    ['solar-panel'] = 2,
    ['flamethrower-turret'] = 2,
    ['assembling-machine-2'] = 2,
    ['steel-furnace'] = 2,
    ['iron-chest'] = 2,
    ['fast-inserter'] = 2,
    ['filter-inserter'] = 2,
    ['accumulator'] = 2,
    ['big-electric-pole'] = 2,
    -- Tier 3
    ['rocket-silo'] = 3,
    ['nuclear-reactor'] = 3,
    ['centrifuge'] = 3,
    ['heat-exchanger'] = 3,
    ['heat-pipe'] = 3,
    ['steam-turbine'] = 3,
    ['artillery-turret'] = 3,
    ['roboport'] = 3,
    ['beacon'] = 3,
    ['assembling-machine-3'] = 3,
    ['electric-furnace'] = 3,
    ['substation'] = 3,
    ['laser-turret'] = 3,
    ['steel-chest'] = 3,
    ['stack-inserter'] = 3,
    ['stack-filter-inserter'] = 3,
    ['logistic-chest-active-provider'] = 3,
    ['logistic-chest-passive-provider'] = 3,
    ['logistic-chest-buffer'] = 3,
    ['logistic-chest-storage'] = 3,
    ['logistic-chest-requester'] = 3
}

--Creates rich text icons of the tiered entities
local tier_2_items = ''
local tier_3_items = ''

local tier_2_counter = 0
local tier_3_counter = 0

for k, v in pairs(entity_tiers) do
    if (v == 3) then
        tier_3_items = tier_3_items .. ' [entity=' .. k .. ']'
        tier_3_counter = tier_3_counter + 1
    elseif (v == 2) then
        tier_2_items = tier_2_items .. ' [entity=' .. k .. ']'
        tier_2_counter = tier_2_counter + 1
    end

    if tier_3_counter > 14 then
        tier_3_counter = 0
        tier_3_items = tier_3_items .. '\n'
    elseif tier_2_counter > 14 then
        tier_2_counter = 0
        tier_2_items = tier_2_items .. '\n'
    end
end

local tile_tiers_entities = 'You may only build the factory on:\n'
local tile_tiers_entities_counter = 0

for k, _ in pairs(tile_tiers) do
    tile_tiers_entities = tile_tiers_entities .. ' [tile=' .. k .. '] ' .. k
    tile_tiers_entities_counter = tile_tiers_entities_counter + 1
    if tile_tiers_entities_counter == 3 or tile_tiers_entities_counter == 5 then
        --tile_tiers_entities_counter = 0
        tile_tiers_entities = tile_tiers_entities .. '\n'
    end
end

ScenarioInfo.add_map_extra_info(
    tile_tiers_entities ..
        [[


Exceptions:
 [item=burner-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=car] [item=tank] [item=pipe] [item=pipe-to-ground] [item=offshore-pump]
 [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt]

Stone bricks provide ground support for most buildings/entities,
but some require better ground support!

Ground support minimum concrete:
]] ..
            tier_2_items .. [[

Ground support minimum refined concrete:
]] .. tier_3_items
)

--- The logic for checking that there are the correct ground support under the entity's position
RestrictEntities.set_keep_alive_callback(
    Token.register(
        function(entity)
            local get_tile = entity.surface.get_tile
            local area = entity.bounding_box
            local left_top = area.left_top
            local right_bottom = area.right_bottom
            local name = entity.name

            if name == 'entity-ghost' then
                name = entity.ghost_name
            end

            local entity_tier = entity_tiers[name] or 1

            for x = floor(left_top.x), floor(right_bottom.x) do
                for y = floor(left_top.y), floor(right_bottom.y) do
                    local tile_name = get_tile(x, y).name
                    local tile_tier = tile_tiers[tile_name] or 0

                    if entity_tier > tile_tier then
                        return false
                    end
                end
            end
            return true
        end
    )
)

local function print_floating_text(player, entity, text, color)
    color = color or Color.white
    local surface = player.surface
    local position = entity.position

    return surface.create_entity {
        name = 'tutorial-flying-text',
        color = color,
        text = text,
        position = position
    }
end

--- Warning for players when their entities are destroyed (needs to be pre because of the stack)
local function on_destroy(event)
    local p = game.get_player(event.player_index)
    local name = event.stack.name
    if p and p.valid then
        if not (name == 'blueprint') then
            local entity = event.created_entity
            local tier = '[tile=stone-path]'
            if (entity_tiers[name] == 2) then
                tier = '[tile=concrete]'
            elseif (entity_tiers[name] == 3) then
                tier = '[tile=refined-concrete]'
            end
            local text = 'Requires at least ' .. tier
            --local text = '[color=yellow]This [/color][item=' .. name .. '][color=yellow] cannot be placed here, it needs ground support of at least [/color]' .. tier
            print_floating_text(p, entity, text)
        else
            p.print('[color=yellow]Some parts of this [/color][color=red]blueprint[/color][color=yellow] cannot be placed here, they need better ground support![/color]')
        end
    end
end

Event.add(RestrictEntities.events.on_pre_restricted_entity_destroyed, on_destroy)

--Creating the starting circle
local circle = b.circle(50)
local stone_circle = b.change_tile(circle, true, 'stone-path')

local map = b.if_else(stone_circle, b.full_shape)

return map
