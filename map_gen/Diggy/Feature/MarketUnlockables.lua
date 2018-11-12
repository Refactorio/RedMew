-- dependencise

-- this
local MarketUnlockables = {}

local marked_prototype_items = {}

local function market_prototype_add(self_level, self_price, self_name)
    if (not marked_prototype_items[self_level]) then
        table.insert(marked_prototype_items, self_level, {})
    end
    table.insert(marked_prototype_items[self_level], {price = self_price, name = self_name})
end

function MarketUnlockables.initalize_unlockables()
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
        local numberlen = math.floor(math.log10(number)+1)
        precision = (numberlen >= 8) and (precision+1) or precision
        number = number/10^(numberlen-precision)
        number = math.floor(number)*10^(numberlen-precision)
        while (prev_number >= number) do
            number = (prev_number > number) and number or number + math.ceil(5*10^(numberlen-3))
        end
        
        levelcost[i] = number
        prev_number = number

        
    end
    
    -- Add new market unlockables here
    -- market_prototype_add(unlock_level, price, prototype_name)
    market_prototype_add(1, 50, 'raw-fish')
    market_prototype_add(1, 50, 'steel-axe')
    market_prototype_add(2, 50, 'small-lamp')
    market_prototype_add(2, 25, 'stone-brick')
    market_prototype_add(2, 125, 'stone-wall')
    market_prototype_add(3, 850, 'submachine-gun')
    market_prototype_add(3, 850, 'shotgun')
    market_prototype_add(3, 50, 'firearm-magazine')
    market_prototype_add(3, 50, 'shotgun-shell')
    market_prototype_add(3, 500, 'light-armor')
    market_prototype_add(11, 750, 'heavy-armor')
    market_prototype_add(13, 100, 'piercing-rounds-magazine')
    market_prototype_add(13, 100, 'piercing-shotgun-shell')
    market_prototype_add(13, 1500, 'modular-armor')
    market_prototype_add(16, 1000, 'landfill')
    market_prototype_add(30, 250, 'uranium-rounds-magazine')
    market_prototype_add(30, 1000, 'combat-shotgun')
    market_prototype_add(1, 20, 'raw-wood')
    
      for lvl, v in pairs(marked_prototype_items) do
          for _, w in ipairs(v) do
              table.insert(unlockables, {level = lvl, stone = levelcost[lvl], type = 'market', prototype = w})
          end
      end
      
    return unlockables
end

return MarketUnlockables
