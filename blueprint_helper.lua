-- Soft mod version of Blueprint Flipper and Turner https://mods.factorio.com/mods/Marthen/Blueprint_Flip_Turn

local Event = require 'utils.event'
local Gui = require 'utils.gui'

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
        local ents = cursor.get_blueprint_entities()
        if ents then
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
        local ents = cursor.get_blueprint_entities()
        if ents then
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

local function valid_filter(entity_name)
    local prototype = game.entity_prototypes[entity_name]

    if not prototype then
        return false
    end

    -- 'not-blueprintable' doesn't seem to work - grilledham 2018.05.20
    return prototype.has_flag('player-creation') and not prototype.has_flag('placeable-off-grid')
end

local function convert(player, data)
    local cursor = getBlueprintCursorStack(player)
    if not cursor then
        return
    end

    local entities = cursor.get_blueprint_entities()
    if not entities then
        return
    end

    local filters = {}
    for _, filter in pairs(data) do
        local from = filter.from.elem_value
        local to = filter.to.elem_value

        if from and to then
            if valid_filter(from) and valid_filter(to) then
                filters[from] = to
            else
                player.print('invalid filter: ' .. from .. ' => ' .. to)
            end
        end
    end

    for _, e in ipairs(entities) do
        local to_name = filters[e.name]
        if to_name then
            e.name = to_name
        end
    end

    cursor.set_blueprint_entities(entities)
end

-- Gui implementation.

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local flip_h_button_name = Gui.uid_name()
local flip_v_button_name = Gui.uid_name()
local convert_button_name = Gui.uid_name()

local function player_joined(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {name = main_button_name, type = 'sprite-button', sprite = 'item/blueprint'}
end

local function toggle(event)
    local left = event.player.gui.left

    local main_frame = left[main_frame_name]
    if main_frame and main_frame.valid then
        Gui.remove_data_recursivly(main_frame)
        main_frame.destroy()
    else
        main_frame =
            left.add {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = 'Blueprint Helper'
        }
        local scroll_pane =
            main_frame.add {type = 'scroll-pane', direction = 'vertical', vertical_scroll_policy = 'auto'}
        scroll_pane.style.maximal_height = 500

        -- Flipper.

        local flipper_frame = scroll_pane.add {type = 'frame', caption = 'Flipper', direction = 'vertical'}

        flipper_frame.add {
            type = 'label',
            caption = 'With blueprint in cursor click on button below to flip blueprint.'
        }
        flipper_frame.add {
            type = 'label',
            caption = 'Obviously this wont work correctly with refineries or chemical plants.'
        }
        flipper_frame.add {
            type = 'button',
            name = flip_h_button_name,
            caption = 'Flip Horizontal'
        }
        flipper_frame.add {
            type = 'button',
            name = flip_v_button_name,
            caption = 'Flip Vertical'
        }

        -- Converter.

        local filter_frame = scroll_pane.add {type = 'frame', caption = 'Entity Converter', direction = 'vertical'}

        filter_frame.add {type = 'label', caption = 'Set filters then with blueprint in cursor click convert'}

        local filter_table = filter_frame.add {type = 'table', column_count = 13}

        local filters = {}

        for _ = 1, 3 do
            for _ = 1, 3 do
                local filler = filter_table.add {type = 'label'}
                filler.style.minimal_width = 16

                local from_filter =
                    filter_table.add {
                    type = 'choose-elem-button',
                    elem_type = 'entity'
                }
                filter_table.add {type = 'label', caption = '=>'}

                local to_filter =
                    filter_table.add {
                    type = 'choose-elem-button',
                    elem_type = 'entity'
                }

                table.insert(filters, {from = from_filter, to = to_filter})
            end

            local filler = filter_table.add {type = 'label'}
            filler.style.minimal_width = 16
        end

        local filter_button = filter_frame.add {type = 'button', name = convert_button_name, caption = 'convert'}
        Gui.set_data(filter_button, filters)

        main_frame.add {type = 'button', name = main_button_name, caption = 'close'}
    end
end

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    flip_h_button_name,
    function(event)
        flip_h(event.player)
    end
)

Gui.on_click(
    flip_v_button_name,
    function(event)
        flip_v(event.player)
    end
)

Gui.on_click(
    convert_button_name,
    function(event)
        local data = Gui.get_data(event.element)
        convert(event.player, data)
    end
)

Event.add(defines.events.on_player_joined_game, player_joined)
