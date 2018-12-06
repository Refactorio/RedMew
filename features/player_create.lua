local Game = require 'utils.game'
local Event = require 'utils.event'

local info = require 'features.gui.info'
local join_msgs = require 'resources.join_messages'

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)

    if not player or not player.valid then
        return
    end

    player.insert {name = 'iron-gear-wheel', count = 8}
    player.insert {name = 'iron-plate', count = 16}

    player.print('Welcome to this map created by the RedMew team. You can join our discord at: redmew.com/discord')
    player.print('Click the question mark in the top left corner for server information and map details.')
    player.print(table.get_random_weighted(join_msgs, 1, 2))

    local gui = player.gui
    gui.top.style = 'slot_table_spacing_horizontal_flow'
    gui.left.style = 'slot_table_spacing_vertical_flow'
    if info ~= nil then
        info.show_info({player = player})
    end

    if _CHEATS then
        local force = player.force
        local i = player.insert

        i {name = 'power-armor-mk2', count = 1}
        local p_armor = player.get_inventory(5)[1].grid
        local p = p_armor.put
        p({name = 'fusion-reactor-equipment'})
        p({name = 'fusion-reactor-equipment'})
        p({name = 'fusion-reactor-equipment'})
        p({name = 'fusion-reactor-equipment'})
        p({name = 'personal-roboport-mk2-equipment'})
        p({name = 'personal-roboport-mk2-equipment'})
        p({name = 'personal-laser-defense-equipment'})
        p({name = 'personal-laser-defense-equipment'})
        p({name = 'energy-shield-mk2-equipment'})
        p({name = 'energy-shield-mk2-equipment'})
        p({name = 'night-vision-equipment'})
        p({name = 'battery-mk2-equipment'})
        p({name = 'battery-mk2-equipment'})
        p({name = 'battery-mk2-equipment'})
        p({name = 'belt-immunity-equipment'})
        p({name = 'solar-panel-equipment'})
        i {name = 'steel-axe', count = 10}
        i {name = 'submachine-gun', count = 1}
        i {name = 'uranium-rounds-magazine', count = 1000}
        i {name = 'construction-robot', count = 250}
        i {name = 'electric-energy-interface', count = 50}
        i {name = 'substation', count = 50}
        i {name = 'roboport', count = 10}
        i {name = 'infinity-chest', count = 10}
        i {name = 'small-plane', count = 2}
        i {name = 'coin', count = 20000}
        i {name = 'rocket-part', count = 2}
        i {name = 'computer', count = 2}

        player.cheat_mode = true
        force.manual_mining_speed_modifier = 10
        force.character_running_speed_modifier = 5
        force.character_health_bonus = 100000
    end
end

Event.add(defines.events.on_player_created, player_created)
