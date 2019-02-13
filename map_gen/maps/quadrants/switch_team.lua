local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Game = require 'utils.game'
local abs = math.abs
local Color = require 'resources.color_presets'

local gui = {}

local spawn_locations = {
    quadrant_1 = {64, -64},
    quadrant_2 = {-64, -64},
    quadrant_3 = {-64, 64},
    quadrant_4 = {64, 64}
}

local function teleport(event, quadrant)
    local player = event.player

    if (abs(player.position.x) <= 4 and abs(player.position.y) <= 4) or (player.get_inventory(1).is_empty() and player.get_inventory(2).is_empty() and (player.get_inventory(8) or player.get_inventory(3).is_empty())) then
        player.teleport(spawn_locations['quadrant_'..quadrant])
    else
        local text = '## - You are too heavy for teleportation! Empty your inventory before switching quadrant!'
        player.print(text, Color.red)
    end
end

local function toggle(event)
    local player = event.player
    local left = player.gui.left
    local frame = left['Quadrants.Switch_Team']

    if (frame and event.trigger == nil) then
        Gui.destroy(frame)
        return
    elseif (frame) then
        return
    end

    frame = left.add({name = 'Quadrants.Switch_Team', type = 'frame', direction = 'vertical'})

    local content_flow = frame.add {type = 'flow', direction = 'vertical'}
    local label_flow = content_flow.add {type = 'flow'}

    label_flow.style.horizontally_stretchable = true
    local label = label_flow.add {type = 'label', caption = "Welcome to quadrants!"}
    label.style.single_line = false
    label.style.font = 'default-large-bold'

    local label_flow = content_flow.add {type = 'flow'}
    local label = label_flow.add {type = 'label', caption = "While in spawn, you can switch quadrant!"}
    label.style.single_line = false
    label.style.font = 'default'

    local label_flow = content_flow.add {type = 'flow'}
    local label = label_flow.add {type = 'label', caption = "Go ahead and pick a quadrant you'd like to help out!"}
    label.style.single_line = false
    label.style.font = 'default'

    local left_flow = frame.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    left_flow.add({type = 'button', name = 'Quadrants.Button.1', caption = 'Join quadrant1'})
    left_flow.add({type = 'button', name = 'Quadrants.Button.2', caption = 'Join quadrant2'})

    local left_flow = frame.add {type = 'flow', direction = 'horizontal'}
    left_flow.style.align = 'left'
    left_flow.style.horizontally_stretchable = true

    left_flow.add({type = 'button', name = 'Quadrants.Button.3', caption = 'Join quadrant3'})
    left_flow.add({type = 'button', name = 'Quadrants.Button.4', caption = 'Join quadrant4'})

    local data = {
        frame = frame,
    }

    Gui.set_data(frame, data)
end

Gui.on_click('Quadrants.Button.1', function(event) teleport(event, 1) end)
Gui.on_click('Quadrants.Button.2', function(event) teleport(event, 2) end)
Gui.on_click('Quadrants.Button.3', function(event) teleport(event, 3) end)
Gui.on_click('Quadrants.Button.4', function(event) teleport(event, 4) end)


local function on_player_created(event)
    event.player = Game.get_player_by_index(event.player_index)
    toggle(event)
end

local function update_gui()
    local players = game.connected_players
    for i = #players, 1, -1 do
        local p = players[i]
        local frame = p.gui.left['Quadrants.Switch_Team']
        local data = {player = p}

        if frame and frame.valid and (abs(p.position.x) >= 128 or abs(p.position.y) >= 128) then
            toggle(data)
        elseif not frame and not (abs(p.position.x) > 128 or abs(p.position.y) > 128) then
            toggle(data)
        end
    end
end

Event.add(defines.events.on_player_created, on_player_created)
Event.on_nth_tick(61, update_gui)

return gui
