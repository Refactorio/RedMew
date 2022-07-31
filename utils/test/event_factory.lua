local EventCore = require 'utils.event_core'

local Public = {}

Public.raise = EventCore.on_event

function Public.position(position)
    local x = position.x or position[1]
    local y = position.y or position[2]

    position.x = x
    position[1] = x
    position.y = y
    position[2] = y

    return position
end

function Public.area(area)
    local left_top = area.left_top or area[1]
    local right_bottom = area.right_bottom or area[2]

    Public.position(left_top)
    Public.position(right_bottom)

    area.left_top = left_top
    area[1] = left_top
    area.right_bottom = right_bottom
    area[2] = right_bottom

    return area
end

function Public.on_gui_click(element)
    return {
        name = defines.events.on_gui_click,
        tick = game.tick,
        element = element,
        player_index = element.player_index,
        button = defines.mouse_button_type.left,
        alt = false,
        control = false,
        shift = false
    }
end

function Public.on_gui_text_changed(element, text)
    return {
        name = defines.events.on_gui_text_changed,
        tick = game.tick,
        element = element,
        player_index = element.player_index,
        text = text
    }
end

function Public.on_gui_checked_state_changed(element)
    return {
        name = defines.events.on_gui_checked_state_changed,
        tick = game.tick,
        element = element,
        player_index = element.player_index
    }
end

function Public.on_player_deconstructed_area(player_index, surface, area, item)
    return {
        name = defines.events.on_player_deconstructed_area,
        tick = game.tick,
        player_index = player_index,
        surface = surface,
        area = Public.area(area),
        item = item,
        alt = false
    }
end

function Public.do_player_deconstruct_area(cursor, player, area, optional_skip_fog_of_war)
    cursor.deconstruct_area({
        surface = player.surface,
        force = player.force,
        area = area,
        by_player = player,
        skip_fog_of_war = optional_skip_fog_of_war
    })

    local event = Public.on_player_deconstructed_area(player.index, player.surface, area, cursor.name)
    Public.raise(event)
end

function Public.on_player_died(player_index)
    return {name = defines.events.on_player_died, tick = game.tick, player_index = player_index, cause = nil}
end

return Public
