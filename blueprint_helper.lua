-- Soft mod version of Blueprint Flipper and Turner https://mods.factorio.com/mods/Marthen/Blueprint_Flip_Turn

local Event = require 'utils.event'

local function getBlueprintCursorStack(player)
    local cursor = player.cursor_stack
    if
        cursor.valid_for_read and (cursor.name == 'blueprint' or cursor.name == 'blueprint-book') and
            cursor.is_blueprint_setup()
     then --check if is a blueprint, work in book as well
        return cursor
    end
    return nil
end

local function flip_v(player)
    local cursor = getBlueprintCursorStack(player)
    if cursor then
        if cursor.get_blueprint_entities() ~= nil then
            local ents = cursor.get_blueprint_entities()
            for i = 1, #ents do
                local dir = ents[i].direction or 0
                if ents[i].name == 'curved-rail' then
                    ents[i].direction = (13 - dir) % 8
                elseif ents[i].name == 'storage-tank' then
                    if ents[i].direction == 2 or ents[i].direction == 6 then
                        ents[i].direction = 4
                    else
                        ents[i].direction = 2
                    end
                elseif ents[i].name == 'rail-signal' or ents[i].name == 'rail-chain-signal' then
                    if dir == 1 then
                        ents[i].direction = 7
                    elseif dir == 2 then
                        ents[i].direction = 6
                    elseif dir == 3 then
                        ents[i].direction = 5
                    elseif dir == 5 then
                        ents[i].direction = 3
                    elseif dir == 6 then
                        ents[i].direction = 2
                    elseif dir == 7 then
                        ents[i].direction = 1
                    end
                elseif ents[i].name == 'train-stop' then
                    if dir == 2 then
                        ents[i].direction = 6
                    elseif dir == 6 then
                        ents[i].direction = 2
                    end
                else
                    ents[i].direction = (12 - dir) % 8
                end
                ents[i].position.y = -ents[i].position.y
                if ents[i].drop_position then
                    ents[i].drop_position.y = -ents[i].drop_position.y
                end
                if ents[i].pickup_position then
                    ents[i].pickup_position.y = -ents[i].pickup_position.y
                end
            end
            cursor.set_blueprint_entities(ents)
        end
        if cursor.get_blueprint_tiles() ~= nil then
            local ents = cursor.get_blueprint_tiles()
            for i = 1, #ents do
                local dir = ents[i].direction or 0
                ents[i].direction = (12 - dir) % 8
                ents[i].position.y = -ents[i].position.y
            end
            cursor.set_blueprint_tiles(ents)
        end
    end
end

local function flip_h(player)
    local cursor = getBlueprintCursorStack(player)
    if cursor then
        if cursor.get_blueprint_entities() ~= nil then
            local ents = cursor.get_blueprint_entities()
            for i = 1, #ents do
                local dir = ents[i].direction or 0
                if ents[i].name == 'curved-rail' then
                    ents[i].direction = (9 - dir) % 8
                elseif ents[i].name == 'storage-tank' then
                    if ents[i].direction == 2 or ents[i].direction == 6 then
                        ents[i].direction = 4
                    else
                        ents[i].direction = 2
                    end
                elseif ents[i].name == 'rail-signal' or ents[i].name == 'rail-chain-signal' then
                    if dir == 0 then
                        ents[i].direction = 4
                    elseif dir == 1 then
                        ents[i].direction = 3
                    elseif dir == 3 then
                        ents[i].direction = 1
                    elseif dir == 4 then
                        ents[i].direction = 0
                    elseif dir == 5 then
                        ents[i].direction = 7
                    elseif dir == 7 then
                        ents[i].direction = 5
                    end
                elseif ents[i].name == 'train-stop' then
                    if dir == 0 then
                        ents[i].direction = 4
                    elseif dir == 4 then
                        ents[i].direction = 0
                    end
                else
                    ents[i].direction = (16 - dir) % 8
                end
                ents[i].position.x = -ents[i].position.x
                if ents[i].drop_position then
                    ents[i].drop_position.x = -ents[i].drop_position.x
                end
                if ents[i].pickup_position then
                    ents[i].pickup_position.x = -ents[i].pickup_position.x
                end
            end
            cursor.set_blueprint_entities(ents)
        end
        if cursor.get_blueprint_tiles() ~= nil then
            local ents = cursor.get_blueprint_tiles()
            for i = 1, #ents do
                local dir = ents[i].direction or 0
                ents[i].direction = (16 - dir) % 8
                ents[i].position.x = -ents[i].position.x
            end
            cursor.set_blueprint_tiles(ents)
        end
    end
end

local main_button_name = 'blueprint_helper_main_button'
local main_frame_name = 'blueprint_helper_main_frame'
local flip_h_button_name = 'blueprint_helper_flip_h_button'
local flip_v_button_name = 'blueprint_helper_flip_v_button'

local function player_joined(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    local button = player.gui.top.add {name = main_button_name, type = 'sprite-button', sprite = 'item/blueprint'}
    button.style.font = 'default-bold'
    button.style.minimal_height = 38
    button.style.minimal_width = 38
    button.style.top_padding = 2
    button.style.left_padding = 4
    button.style.right_padding = 4
    button.style.bottom_padding = 2
end

local function toggle_main_frame(player)
    local left = player.gui.left

    local main_frame = left[main_frame_name]
    if main_frame and main_frame.valid then
        main_frame.destroy()
    else
        main_frame =
            left.add {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = 'Blueprint Helper'
        }
        main_frame.add {
            type = 'label',
            caption = 'With blueprint in cursor click on button below to flip blueprint.'
        }
        main_frame.add {
            type = 'label',
            caption = 'Obviously this wont work correctly with refineries or chemical plants.'
        }
        main_frame.add {
            type = 'button',
            name = flip_h_button_name,
            caption = 'Flip Horizontal'
        }
        main_frame.add {
            type = 'button',
            name = flip_v_button_name,
            caption = 'Flip Vertical'
        }
    end
end

local function gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local name = element.name
    if name == main_button_name then
        toggle_main_frame(player)
    elseif name == flip_h_button_name then
        flip_h(player)
    elseif name == flip_v_button_name then
        flip_v(player)
    end
end

Event.add(defines.events.on_player_joined_game, player_joined)
Event.add(defines.events.on_gui_click, gui_click)
