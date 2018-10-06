--[[-- info
    Provides the ability to purchase items from the market.
]]

-- dependencies
local Event = require 'utils.event'
local Token = require 'utils.global_token'
local Task = require 'utils.Task'
local Debug = require 'map_gen.Diggy.Debug'
local Template = require 'map_gen.Diggy.Template'

-- this
local MarketExchange = {}

global.MarketExchange = {
    stone_sent_to_surface = 0,
}

--[[--
    Registers all event handlers.
]]
function MarketExchange.register(cfg)
    local config = cfg.features.MarketExchange
    Event.add(defines.events.on_market_item_purchased, function (event)
        if (1 ~= event.offer_index) then
            return
        end

        global.MarketExchange.stone_sent_to_surface = global.MarketExchange.stone_sent_to_surface + config.stone_to_surface_amount
    end)
end

--[[--
    Initializes the Feature.

    @param cfg Table {@see Diggy.Config}.
]]
function MarketExchange.initialize(cfg)
    local config = cfg.features.MarketExchange
    local market_items = {
        {price = {{config.currency_item, 50}}, offer = {type = 'nothing', effect_description = 'Send ' .. config.stone_to_surface_amount .. ' stone to the surface'}},
    }

    for _, item_prototype in pairs(config.market_inventory) do
        local bulk = item_prototype.bulk or {1}
        for _, bulk_amount in pairs(bulk) do
            table.insert(market_items, {
                price = {{config.currency_item, item_prototype.price * bulk_amount}},
                offer = {type = 'give-item', item = item_prototype.item_name, count = bulk_amount}
            })
        end
    end

    local on_market_timeout_finished = Token.register(function(params)
        Template.market(params.surface, params.position, params.force, params.currency_item, params.market_items)
    end)

    Task.set_timeout_in_ticks(40, on_market_timeout_finished, {
        surface = game.surfaces.nauvis,
        position = {x = 0, y = -5},
        force = game.forces.player,
        currency_item = config.currency_item,
        market_items = market_items,
    })
end

return MarketExchange
