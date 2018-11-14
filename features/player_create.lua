local Game = require 'utils.game'
local Event = require 'utils.event'
local UserGroups = require 'features.user_groups'

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)

    if not player or not player.valid then
        return
    end

    if global.scenario.config.admin_check == true then
        if UserGroups.is_admin(player.name) then
            player.admin = true
            log(player.name .. " promoted to admin via control.")
        end
    end

    if (global.scenario.config.fish_market.enable) then
        player.insert {name = MARKET_ITEM, count = 10}
    end
    player.insert {name = 'iron-gear-wheel', count = 8}
    player.insert {name = 'iron-plate', count = 16}
    player.print('Welcome to our Server. You can join our Discord at: redmew.com/discord')
    player.print('Click the question mark in the top left corner for server infomation and map details.')
    player.print('And remember.. Keep Calm And Spaghetti!')

    local gui = player.gui
    gui.top.style = 'slot_table_spacing_horizontal_flow'
    gui.left.style = 'slot_table_spacing_vertical_flow'
end

Event.add(defines.events.on_player_created, player_created)
