local Event = require 'utils.event'
local Game = require 'utils.game'
local Command = require 'utils.command'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Retailer = require 'features.retailer'
local Ranks = require 'resources.ranks'

local round = math.round
local insert = table.insert
local remove = table.remove

local clean_energy_interface = Token.register(function (params)
    local entity = params.entity
    if not entity or not entity.valid then
        -- already removed o.O
        return
    end

    entity.destroy()
end)

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
                {name = 'coin', count = 30},
                {name = 'small-electric-pole', count = 5},
                {name = 'construction-robot', count = 2},
            },
        },
        {price = 5, name = 'construction-robot'},
        {price = 15, name = 'logistic-robot'},
        {price = 50, name = 'roboport'},
        {price = 5, name = 'logistic-chest-passive-provider'},
        {price = 5, name = 'logistic-chest-active-provider'},
        {price = 5, name = 'logistic-chest-buffer'},
        {price = 5, name = 'logistic-chest-requester'},
        {price = 5, name = 'logistic-chest-storage'},

    }
    local market_items = require 'resources.market_items'

    for i = #market_items, 1, -1 do
        local name = market_items[i].name
        -- cleanup items we don't need, construction bot has to be replaced for convenience
        if name == 'temporary-mining-speed-bonus' or name == 'construction-robot' then
            remove(market_items, i)
        end
    end

    for i = 1, #new_items do
        insert(market_items, i, new_items[i])
    end
end

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

    -- not every item has a ghost, this is the easiest way to prevent errors and stop replacement
    pcall(function()
        surface.create_entity({
            name = 'entity-ghost',
            inner_name = name,
            direction = direction,
            position = position,
            force = force,
        });
        entity.destroy()

        -- attempt to give the item back to the player
        local player = Game.get_player_by_index(event.player_index)
        if not player or not player.valid then
            return
        end

        player.insert(event.stack)
    end)
end)

Command.add('lazy-bastard-bootstrap', {
    description = {'command_description.lazy_bastard_bootstrap'},
    required_rank = Ranks.admin,
}, function(_, player)
    local surface = player.surface
    local force = player.force

    local pos = player.position
    pos.y = round(pos.y - 4)
    pos.x = round(pos.x)

    local bot_count = 3
    local create_entity = surface.create_entity
    local templates = {
        {name = 'medium-electric-pole', force = force, position = {x = pos.x - 2, y = pos.y - 1}},
        {name = 'roboport', force = force, position = {x = pos.x, y = pos.y}},
        {name = 'logistic-chest-storage', force = force, position = {x = pos.x + 1, y = pos.y + 1}},
        {name = 'logistic-chest-storage', force = force, position = {x = pos.x - 2, y = pos.y + 1}},
    }

    for i = 1, #templates do
        local entity = create_entity(templates[i])
        entity.minable = false
        entity.destructible = false
    end

    for _ = 1, bot_count do
        create_entity({name = 'construction-robot', force = force, position = pos})
    end

    local power_source = create_entity({name = 'hidden-electric-energy-interface', position = pos})
    power_source.electric_buffer_size = 30000
    power_source.power_production = 30000
    power_source.destructible = false
    power_source.minable = false

    -- in 7 minutes, remove the power source
    Task.set_timeout(420, clean_energy_interface, {entity = power_source})
end)
