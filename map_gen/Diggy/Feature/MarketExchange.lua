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

local on_init;

--[[--
    Registers all event handlers.
]]
function MarketExchange.register(config)
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
        Template.market(params.surface, params.position, params.player_force, params.currency_item, params.market_items)
    end)

    on_init = function()
        Task.set_timeout_in_ticks(60, on_market_timeout_finished, {
            surface = game.surfaces.nauvis,
            position = {x = 0, y = -5},
            player_force = game.forces.player,
            currency_item = config.currency_item,
            market_items = market_items,
        })
    end


    Event.add(defines.events.on_market_item_purchased, function (event)
        if (1 ~= event.offer_index) then
            return
        end

        global.MarketExchange.stone_sent_to_surface = global.MarketExchange.stone_sent_to_surface + config.stone_to_surface_amount
    end)
end

function MarketExchange.get_extra_map_info(config)
    return 'Market Exchange, trade your stone or send it to the surface'
end

function MarketExchange.on_init()
    if ('function' ~= type(on_init)) then
        error('Expected local on_init in MarketExchange to have a function assigned.')
    end

    on_init()
end

return MarketExchange
