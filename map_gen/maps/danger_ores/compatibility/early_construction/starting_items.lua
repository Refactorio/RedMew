local item_list = require 'config'.player_create.starting_items

if script.active_mods['early_construction'] then
  table.insert(item_list, { count =   1, name = 'early-construction-light-armor' })
  table.insert(item_list, { count =   1, name = 'early-construction-equipment' })
  table.insert(item_list, { count = 100, name = 'early-construction-robot' })
end
