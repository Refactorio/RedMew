local Retailer = require 'features.retailer'
local Events = require 'utils.event'

local function on_market_purchase(event)
    local item = event.item
    local name = item.name
    local player = event.player
    local force = player.force

    if name == 'tank' then
        player.insert('tank')
        return
    end

    local research = force.technologies[name]
    if research and research.valid then
        research.enabled = true
        Retailer.remove_item(event.group_name, name)
    end
end

Events.add(Retailer.events.on_market_purchase, on_market_purchase)


--[[

    raise_event(Retailer.events.on_market_purchase, {
        item = item,
        count = stack_count,
        player = player,
        group_name = market_group,
    })

]]
