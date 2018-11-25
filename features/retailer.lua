local Debug = require 'map_gen.Diggy.Debug'
local Global = require 'utils.global'
local format = string.format
local insert = table.insert

local Retailer = {}

---Global storage
---Markets are indexed by the group_name and is a sequential list of LuaEntities
---Items are indexed by the group name and is a list indexed by the item name and contains the prices per item
local memory = {
    markets = {},
    items = {},
}

Global.register({
    memory = memory,
}, function (tbl)
    memory = tbl.memory
end)

---Add a market to the group_name retailer.
---@param group_name string
---@param market_entity LuaEntity
function Retailer.add_market(group_name, market_entity)
    if not memory.markets[group_name] then
        memory.markets[group_name] = {market_entity}
        return
    end

    insert(memory.markets[group_name], market_entity)
end

---Sets an item for all the group_name markets.
---@param group_name string
---@param item_name string
---@param prices table associative table where the key is the currency item and the value the amount of it
function Retailer.set_item(group_name, item_name, prices)
    if not memory.items[group_name] then
        memory.items[group_name] = {}
    end

    local market_format_prices = {}
    for currency, amount in pairs(prices) do
        insert(market_format_prices, {currency, amount})
    end

    memory.items[group_name][item_name] = market_format_prices
end

---Returns all item for the group_name retailer.
---@param group_name string
function Retailer.get_items(group_name)
    return memory.items[group_name] or {}
end

---Removes an item from the markets for the group_name retailer.
---@param group_name string
---@param item_name string
function Retailer.remove_item(group_name, item_name)
    if not memory.items[group_name] then
        return
    end

    memory.items[group_name][item_name] = nil
end

---Ships the current list of items with their prices to all markets for the group_name retailer.
---@param group_name string
function Retailer.ship_items(group_name)
    local markets = memory.markets[group_name]
    if not markets then
        return
    end

    local market_items = memory.items[group_name]
    if not market_items then
        -- items have not been added yet
        return
    end

    for _, market in ipairs(markets) do
        if market.valid then
            -- clean the current inventory
            local remove_market_item = market.remove_market_item
            -- remove re-indexes the offers, to prevent shifting, go backwards
            local current_market_items = market.get_market_items()
            if current_market_items then
                for current_index = #current_market_items, 1, -1 do
                    remove_market_item(current_index)
                end
            end

            -- re-add the whole list
            local add_market_item = market.add_market_item
            for item_name, prices in pairs(market_items) do
                add_market_item({
                    price = prices,
                    offer = {type = 'give-item', item = item_name, count = 1}
                })
            end
        end
    end
end

return Retailer
