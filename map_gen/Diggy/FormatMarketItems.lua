-- dependencies

-- this
local FormatMarketItems = {}

local market_prototype_items = {}
local insert = table.insert
--- Returns the correct format for Diggy.Feature.MarketExhange.lua to process
-- @param self_level integer of the level the given item should be unlocked at
-- @param self_price integer of the price in the configured currency_item the given item should cost
-- @param self_name string of the factorio entity prototype-name
--
local function add(self_level, self_price, self_name)
    if (not market_prototype_items[self_level]) then
        insert(market_prototype_items, self_level, {})
    end
    insert(market_prototype_items[self_level], {price = self_price, name = self_name})
end

--- handles the unlockable market items from Config.lua in map_gen.Diggy
-- serves as a handler for an array of items and passes it on to FormatMarketItems.add() that returns the correct format for Diggy.Feature.MarketExhange.lua to process.
-- @param items array of items where each item is an table with keys: level (integer level it unlocks at), price (price in the configured currency_item) and name (has to be an entity's prototype-name)
-- @returns table of items formated in the correct way for Diggy.Feature.MarketExhange.lua to interpret.
--
function FormatMarketItems.initalize_unlockables(items)
    local unlockables = {}
    for _, item in ipairs(items) do
        add(item.level, item.price, item.name)
    end
    
        for lvl, v in pairs(market_prototype_items) do
            for _, w in ipairs(v) do
                insert(unlockables, {level = lvl, type = 'market', prototype = w})
            end
        end
      
    return unlockables
end

return FormatMarketItems
