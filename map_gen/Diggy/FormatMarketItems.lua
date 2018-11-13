-- dependencies

-- this
local FormatMarketItems = {}

local market_prototype_items = {}
local insert = table.insert

function FormatMarketItems.add(self_level, self_price, self_name)
    if (not market_prototype_items[self_level]) then
        insert(market_prototype_items, self_level, {})
    end
    insert(market_prototype_items[self_level], {price = self_price, name = self_name})
end

function FormatMarketItems.initalize_unlockables(items)
    local unlockables = {}  
    -- handles the unlockables from Config.lua in map_gen.Diggy
    for _, item in ipairs(items) do
        FormatMarketItems.add(item.level, item.price, item.name)
    end
    
        for lvl, v in pairs(market_prototype_items) do
            for _, w in ipairs(v) do
                insert(unlockables, {level = lvl, type = 'market', prototype = w})
            end
        end
      
    return unlockables
end

return FormatMarketItems
