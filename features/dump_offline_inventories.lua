-- This feature allows you to turn on anti-hoarding so that X minutes after a player leaves the game 
-- the resources in their inventory are returned to the teams

-- To do
-- What if player has no body when they leave?
-- What if players is kicked?
-- Do we want to allow donators and admins to keep their inventories as a perk? Or is that too pay to win?

local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local corpse_util = require 'features.corpse_util'

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local config = global.config.dump_offline_inventories
local offline_timout_mins = config.offline_timout_mins
local offline_player_queue = {}

--[[local config = global.config
config.dump_offline_inventories = {
    enabled = true,
    offline_timout_mins = 1,   -- time after which a player logs off that their inventory is provided to the team
}]]--

/sc
local player = game.players["Tigress88"]
local inv_main = player.get_inventory(defines.inventory.character_main)
local inv_trash = player.get_inventory(defines.inventory.character_trash)
local inv_main_contents = inv_main.get_contents()
local inv_trash_contents = inv_trash.get_contents()
local inv_corpse_size = (#inv_main - inv_main.count_empty_stacks()) + (#inv_trash - inv_trash.count_empty_stacks())
local position = player.position
local corpse = player.surface.create_entity{name="character-corpse", position=position, inventory_size = inv_corpse_size, player_index = 2}
corpse.active = false

local inv_corpse = corpse.get_inventory(defines.inventory.character_corpse)

local success_main = true
local success_trash = true
local inserted = nil


for item_name, count in pairs(inv_main_contents) do
    inv_corpse.insert({name = item_name, count = count})
end
for item_name, count in pairs(inv_trash_contents) do
    inv_corpse.insert({name = item_name, count = count})
end


inv_main.clear()
inv_trash.clear()

local text = player.name .. "'s inventory (offline)"
local tag = player.force.add_chart_tag(player.surface, {
    icon = {type = 'item', name = 'modular-armor'},
    position = position,
    text = text
})



local spawn_player_corpse =
    Token.register(
    function(player)
        if player and player.valid and player.connected == false and offline_player_queue[player.index] then
            -- fetch table of items in main inventory and logistics trash. Leave weapons and armor.
            local inv_main = player.get_inventory(defines.inventory.character_main)
            local inv_trash = player.get_inventory(defines.inventory.character_trash)

            local inv_main_contents = inv_main.get_contents()
            local inv_trash_contents = inv_trash.get_contents()
            local inv_corpse_size = (#inv_main - inv_main.count_empty_stacks()) + (#inv_trash - inv_trash.count_empty_stacks())
            -- create corpse
            local position = player.position
            local corpse = player.surface.create_entity{name="character-corpse", position=position, inventory_size = inv_corpse_size, player_index = player.index}
            corpse.active = false

            local inv_corpse = corpse.get_inventory(defines.inventory.character_corpse)

            for item_name, count in pairs(inv_main_contents) do
                inv_corpse.insert({name = item_name, count = count})
            end
            for item_name, count in pairs(inv_trash_contents) do
                inv_corpse.insert({name = item_name, count = count})
            end

            inv_main.clear()
            inv_trash.clear()

                local text = player.name .. "'s inventory (offline)"
                local tag = player.force.add_chart_tag(player.surface, {
                    icon = {type = 'item', name = 'modular-armor'},
                    position = position,
                    text = text
                })
                
                corpse_util.player_corpses[player.index * 0x100000000 + game.tick] = tag
        end
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        offline_player_queue[event.player_index] = nil -- ensures they're not in the offline_player_queue for wealth redistribution
        game.print("Player rejoined. Removed from offline list")
    end
)

Event.add(
    defines.events.on_pre_player_left_game,
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if player.character then -- if player leaves before respawning they wont have a character and we don't need to add them to the list
            offline_player_queue[player_index] = true
            set_timeout_in_ticks(offline_timout_mins*60*60, spawn_player_corpse, player)
            game.print("Player left. Added to offline list")
        end
    end
)