local floor = math.floor

local RestrictEntities = require 'map_gen.shared.entity_placement_restriction'
local Event = require 'utils.event'
local b = require 'map_gen.shared.builders'

--- Items explicitly allowed on ores
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

local tiles_tier_1 = {
    ['stone-path'] = true
}

local tiles_tier_2 = {
    ['concrete'] = true,
    ['hazard-concrete-right'] = true,
    ['hazard-concrete-left'] = true
}

local tiles_tier_3 = {
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-right'] = true,
    ['refined-hazard-concrete-left'] = true
}


local tier_2 = {
    ['oil-refinery'] = true,
    ['chemical-plant'] = true,
    ['storage-tank'] = true,
    ['straight-rail'] = true,
    ['curved-rail'] = true,
    ['train-stop'] = true,
    ['solar-panel'] = true,
    ['flamethrower-turret'] = true,
    ['assembling-machine-2'] = true,
    ['steel-furnace'] = true,
    ['iron-chest'] = true,
    ['fast-inserter'] = true,
    ['filter-inserter'] = true,
    ['accumulator'] = true,
    ['big-electric-pole'] = true

}

local tier_3 = {
    ['rocket-silo'] = true,
    ['nuclear-reactor'] = true,
    ['centrifuge'] = true,
    ['heat-exchanger'] = true,
    ['heat-pipe'] = true,
    ['steam-turbine'] = true,
    ['artillery-turret'] = true,
    ['roboport'] = true,
    ['beacon'] = true,
    ['assembling-machine-3'] = true,
    ['electric-furnace'] = true,
    ['substation'] = true,
    ['laser-turret'] = true,
    ['steel-chest'] = true,
    ['stack-inserter'] = true,
    ['stack-filter-inserter'] = true,
    ['logistic-chest-active-provider'] = true,
    ['logistic-chest-passive-provider'] = true,
    ['logistic-chest-buffer'] = true,
    ['logistic-chest-storage'] = true,
    ['logistic-chest-requester'] = true
}

--- The logic for checking that there are resources under the entity's position
RestrictEntities.set_keep_alive_callback(
    function(entity)
        local get_tile = entity.surface.get_tile
        local area = entity.bounding_box
        local left_top = area.left_top
        local right_bottom = area.right_bottom
        local name = entity.name

        if name == 'entity-ghost' then
            name = entity.ghost_name
        end

        local is_tier_2 = tier_2[name]
        local is_tier_3 = tier_3[name]

        for x = floor(left_top.x), floor(right_bottom.x) do
            for y = floor(left_top.y), floor(right_bottom.y) do
                local tile_name = get_tile(x, y).name
                if is_tier_2 then
                    if not (tiles_tier_2[tile_name] or tiles_tier_3[tile_name]) then
                        game.print('tier_2')
                        return false
                    end
                elseif is_tier_3 then
                    if not (tiles_tier_3[tile_name]) then
                        game.print('tier_3')
                        return false
                    end
                else
                    if not (tiles_tier_1[tile_name] or tiles_tier_2[tile_name] or tiles_tier_3[tile_name]) then
                        game.print('tier_1: ' .. tile_name)
                        return false
                    end
                end
            end
        end
        return true
    end
)

--- Warning for players when their entities are destroyed
local function on_destroy(event)
    local p = event.player
    if p and p.valid then
        p.print('You can only build that on top of stone-paths or better. Only belts, mining drills, and power poles are allowed elsewhere.')
    end
end

Event.add(RestrictEntities.events.on_restricted_entity_destroyed, on_destroy)

local shape = b.circle(50)
local stone_path = b.tile('stone-path')

shape = b.invert(shape)
local map = b.if_else(shape, stone_path)

return map
