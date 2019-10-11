local Retailer = require 'features.retailer'
local Events = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'

local function on_market_purchase(event)
    local item = event.item
    local name = item.name
    local player = event.player
    local force = player.force

    if name == 'tank' then
        player.insert('tank')
        game.print({'', '[color=yellow]Warning! ', {'entity-name.' .. name}, ' has been brought by ' .. force.name .. '![/color]'})
        return
    end

    local research = force.technologies[name]
    if research and research.valid then
        research.enabled = true
        Retailer.remove_item(event.group_name, name)
    end
end

Events.add(Retailer.events.on_market_purchase, on_market_purchase)

local spill_items =
    Token.register(
    function(data)
        data.surface.spill_item_stack(data.position, {name = 'coin', count = data.count}, true)
    end
)

local random = math.random

local entity_drop_amount = {--NEEDS BALANCING!
    ['biter-spawner'] = {low = 2, high = 10, chance = 1},
    ['spitter-spawner'] = {low = 2, high = 10, chance = 1},
    ['small-worm-turret'] = {low = 2, high = 5, chance = 0.5},
    ['medium-worm-turret'] = {low = 5, high = 7, chance = 0.5},
    ['big-worm-turret'] = {low = 5, high = 10, chance = 0.5},
    ['behemoth-worm-turret'] = {low = 5, high = 15, chance = 0.4},
    -- default is 0, no chance of coins dropping from biters/spitters
    ['small-biter'] = {low = 1, high = 2, chance = 0.05},
    ['small-spitter'] = {low = 2, high = 3, chance = 0.05},
    ['medium-spitter'] = {low = 3, high = 6, chance = 0.05},
    ['big-spitter'] = {low = 5, high = 15, chance = 0.05},
    ['behemoth-spitter'] = {low = 20, high = 30, chance = 0.05},
    ['medium-biter'] = {low = 3, high = 5, chance = 0.05},
    ['big-biter'] = {low = 3, high = 8, chance = 0.05},
    ['behemoth-biter'] = {low = 8, high = 10, chance = 0.05}
}

-- Determines how many coins to drop when enemy entity dies based upon the entity_drop_amount table in config.lua
local function fish_drop_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local bounds = entity_drop_amount[entity.name]
    if not bounds then
        return
    end

    local chance = bounds.chance

    if chance == 0 then
        return
    end

    if chance == 1 or random() <= chance then
        local count = random(bounds.low, bounds.high)
        if count > 0 then
            Task.set_timeout_in_ticks(
                1,
                spill_items,
                {
                    count = count,
                    surface = entity.surface,
                    position = entity.position
                }
            )
        end
    end
end

Events.add(defines.events.on_entity_died, fish_drop_entity_died)

--[[

    raise_event(Retailer.events.on_market_purchase, {
        item = item,
        count = stack_count,
        player = player,
        group_name = market_group,
    })

]]
