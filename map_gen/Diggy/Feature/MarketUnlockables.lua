-- dependencise

-- this
local MarketUnlockables = {}

local marked_prototype_items = {}
local insert = table.insert
local floor = math.floor
local ceil = math.ceil
local log10 = math.log10

function MarketUnlockables.add(self_level, self_price, self_name)
    if (not marked_prototype_items[self_level]) then
        insert(marked_prototype_items, self_level, {})
    end
    insert(marked_prototype_items[self_level], {price = self_price, name = self_name})
end

function MarketUnlockables.initalize_unlockables(items)
    local levelcost = {}
    local unlockables = {}
    local prev_number = 0
    for i = 1,100 do
        local b = 20 -- Default 20 <-- Controls how much stone is needed.
        local start_value = 50 -- The start value/the first level cost
        local formula = b*(i^3)+(start_value-b)
        
        local precision = 2 -- Sets the precision
        
        --Truncates to the precision and prevents dublicates by incrementing with 5 in the third highest place
        local number = formula
        local numberlen = floor(log10(number)+1)
        precision = (numberlen >= 8) and (precision+1) or precision
        number = number/10^(numberlen-precision)
        number = floor(number)*10^(numberlen-precision)
        while (prev_number >= number) do
            number = (prev_number > number) and number or number + ceil(5*10^(numberlen-3))
        end
        
        levelcost[i] = number
        prev_number = number
    end
    
    -- handles the unlockables from Config.lua in map_gen.Diggy
    for _, item in pairs(items) do
        MarketUnlockables.add(item.level, item.price, item.name)
    end
    
      for lvl, v in pairs(marked_prototype_items) do
          for _, w in ipairs(v) do
              insert(unlockables, {level = lvl, stone = levelcost[lvl], type = 'market', prototype = w})
          end
      end
      
    return unlockables
end

return MarketUnlockables
