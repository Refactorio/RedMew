local Event = require 'utils.event'
local Retailer = require 'features.retailer'
local insert = table.insert
local remove = table.remove

if global.config.market.enabled then
    local new_items = {
        {
            name = 'welcome-package',
            name_label = 'Lazy bastard welcome package',
            type = Retailer.item_types.item_package,
            description = 'Contains some goodies to get started',
            sprite = 'achievement/lazy-bastard',
            stack_limit = 1,
            player_limit = 1,
            price = 0,
            items = {
                {name = 'solar-panel', count = 1},
                {name = 'roboport', count = 1},
                {name = 'coin', count = 10},
                {name = 'small-electric-pole', count = 5}
            },
        },
        {price = 5, name = 'construction-robot'},
        {price = 15, name = 'logistic-robot'},
        {price = 50, name = 'roboport'},

    }
    local market_items = require 'resources.market_items'

    for i = #market_items, 1, -1 do
        local name = market_items[i].name
        -- cleanup items we don't need, construction bot has to be replaced for convenience
        if name == 'temporary-mining-speed-bonus' or name == 'construction-robot' or name == 'steel-axe' then
            remove(market_items, i)
        end
    end

    for i = 1, #new_items do
        insert(market_items, i, new_items[i])
    end
end


-- disable pickaxes from the start
Event.on_init(function ()
    local recipes = game.forces.player.recipes
    recipes['iron-axe'].enabled = false
    recipes['steel-axe'].enabled = false
end)

-- ensure the recipes are disabled all the time
Event.add(defines.events.on_research_finished, function (event)
    local recipes = event.research.force.recipes
    recipes['iron-axe'].enabled = false
    recipes['steel-axe'].enabled = false
end)

-- players cannot build anything, just place ghosts
Event.add(defines.events.on_built_entity, function(event)
    local entity = event.created_entity
    if not entity or not entity.valid then
        return
    end

    local name = entity.name

    if name == 'entity-ghost' then
        return
    end

    -- replace the entity by a ghost
    local direction = entity.direction
    local position = entity.position
    local surface = entity.surface
    local force = entity.force
    entity.destroy()
    surface.create_entity({
        name = 'entity-ghost',
        inner_name = name,
        direction = direction,
        position = position,
        force = force,
    });

    -- attempt to give the item back to the player
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    player.insert(event.stack)
end)
