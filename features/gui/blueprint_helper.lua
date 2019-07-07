-- Soft mod version of Blueprint Flipper and Turner https://mods.factorio.com/mods/Marthen/Blueprint_Flip_Turn

local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'

local player_filters = {}

Global.register(
    player_filters,
    function(tbl)
        player_filters = tbl
    end
)

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

local function flip_v(cursor)
    local entities = cursor.get_blueprint_entities()
    if entities ~= nil then
        for i = 1, #entities do
            local entity = entities[i]
            local dir = entity.direction or 0

            if entity.name == 'curved-rail' then
                entity.direction = (13 - dir) % 8
            elseif entity.name == 'storage-tank' then
                if entity.direction == 2 or entity.direction == 6 then
                    entity.direction = 4
                else
                    entity.direction = 2
                end
            elseif entity.name == 'rail-signal' or entity.name == 'rail-chain-signal' then
                if dir == 1 then
                    entity.direction = 7
                elseif dir == 2 then
                    entity.direction = 6
                elseif dir == 3 then
                    entity.direction = 5
                elseif dir == 5 then
                    entity.direction = 3
                elseif dir == 6 then
                    entity.direction = 2
                elseif dir == 7 then
                    entity.direction = 1
                end
            elseif entity.name == 'train-stop' then
                if dir == 2 then
                    entity.direction = 6
                elseif dir == 6 then
                    entity.direction = 2
                end
            else
                entity.direction = (12 - dir) % 8
            end

            entity.position.y = -entity.position.y

            if entity.drop_position then
                entity.drop_position.y = -entity.drop_position.y
            end
            if entity.pickup_position then
                entity.pickup_position.y = -entity.pickup_position.y
            end

            local input_priority = entity.input_priority
            if input_priority == 'left' then
                entity.input_priority = 'right'
            elseif input_priority == 'right' then
                entity.input_priority = 'left'
            end
            local output_priority = entity.output_priority
            if output_priority == 'left' then
                entity.output_priority = 'right'
            elseif output_priority == 'right' then
                entity.output_priority = 'left'
            end
        end

        cursor.set_blueprint_entities(entities)
    end

    local tiles = cursor.get_blueprint_tiles()
    if tiles ~= nil then
        for i = 1, #tiles do
            local tile = tiles[i]
            local dir = tile.direction or 0
            tile.direction = (12 - dir) % 8
            tile.position.y = -tile.position.y
        end

        cursor.set_blueprint_tiles(entities)
    end
end

local function flip_h(cursor)
    local entities = cursor.get_blueprint_entities()
    if entities ~= nil then
        for i = 1, #entities do
            local entity = entities[i]
            local dir = entity.direction or 0

            if entity.name == 'curved-rail' then
                entity.direction = (9 - dir) % 8
            elseif entity.name == 'storage-tank' then
                if entity.direction == 2 or entity.direction == 6 then
                    entity.direction = 4
                else
                    entity.direction = 2
                end
            elseif entity.name == 'rail-signal' or entity.name == 'rail-chain-signal' then
                if dir == 0 then
                    entity.direction = 4
                elseif dir == 1 then
                    entity.direction = 3
                elseif dir == 3 then
                    entity.direction = 1
                elseif dir == 4 then
                    entity.direction = 0
                elseif dir == 5 then
                    entity.direction = 7
                elseif dir == 7 then
                    entity.direction = 5
                end
            elseif entity.name == 'train-stop' then
                if dir == 0 then
                    entity.direction = 4
                elseif dir == 4 then
                    entity.direction = 0
                end
            else
                entity.direction = (16 - dir) % 8
            end

            entity.position.x = -entity.position.x

            if entity.drop_position then
                entity.drop_position.x = -entity.drop_position.x
            end
            if entity.pickup_position then
                entity.pickup_position.x = -entity.pickup_position.x
            end

            local input_priority = entity.input_priority
            if input_priority == 'left' then
                entity.input_priority = 'right'
            elseif input_priority == 'right' then
                entity.input_priority = 'left'
            end
            local output_priority = entity.output_priority
            if output_priority == 'left' then
                entity.output_priority = 'right'
            elseif output_priority == 'right' then
                entity.output_priority = 'left'
            end
        end

        cursor.set_blueprint_entities(entities)
    end

    local tiles = cursor.get_blueprint_tiles()
    if tiles ~= nil then
        for i = 1, #tiles do
            local tile = tiles[i]
            local dir = tile.direction or 0
            tile.direction = (16 - dir) % 8
            tile.position.x = -tile.position.x
        end

        cursor.set_blueprint_tiles(tiles)
    end
end

local function build_filters(data)
    local filters = {}
    for _, filter in pairs(data) do
        local from = filter.from.parent.caption
        local to = filter.to.parent.caption

        if from ~= '' and to ~= '' then
            filters[from] = to
        end
    end

    return filters
end

local function convert(cursor, filters)
    local entities = cursor.get_blueprint_entities()
    if not entities then
        return
    end

    for _, e in ipairs(entities) do
        local to_name = filters[e.name]
        if to_name then
            e.name = to_name
        end
    end

    cursor.set_blueprint_entities(entities)
end

local filter_blacklist = {
    ['escape-pod-assembler'] = true,
    ['escape-pod-lab'] = true,
    ['infinity-chest'] = true,
    ['simple-entity-with-force'] = true,
    ['simple-entity-with-owner'] = true,
    ['electric-energy-interface'] = true,
    ['heat-interface'] = true,
    ['infinity-pipe'] = true,
    ['player-port'] = true,
    ['escape-pod-power'] = true,
    ['bait-chest'] = true,
    ['cutscene-gun-turret'] = true,
    ['blue-chest'] = true,
    ['market'] = true,
    ['red-chest'] = true
}

local cached_valid_filters = nil

local function build_valid_filters()
    local filters = {}
    local count = 0

    for name, data in pairs(game.entity_prototypes) do
        local has_flag = data.has_flag
        if has_flag('player-creation') and not has_flag('placeable-off-grid') and not filter_blacklist[name] then
            count = count + 1
            filters[count] = name
        end
    end

    return filters
end

local function get_valid_filters()
    if cached_valid_filters == nil then
        cached_valid_filters = build_valid_filters()
    end

    return cached_valid_filters
end

-- Gui implementation.
local minimal_width = 400

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local flip_h_button_name = Gui.uid_name()
local flip_v_button_name = Gui.uid_name()
local convert_button_name = Gui.uid_name()

local filter_button_name = Gui.uid_name()
local filter_element_name = Gui.uid_name()
local filters_table_name = Gui.uid_name()
local filter_table_close_button_name = Gui.uid_name()
local filter_table_clear_name = Gui.uid_name()
local clear_all_filters_name = Gui.uid_name()

local function player_joined(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add(
        {
            name = main_button_name,
            type = 'sprite-button',
            sprite = 'item/blueprint',
            tooltip = {'blueprint_helper.tooltip'}
        }
    )
end

local function draw_filters_table(event)
    local center = event.player.gui.center

    if center[filters_table_name] then
        return
    end

    local frame =
        center.add {
        type = 'frame',
        name = filters_table_name,
        direction = 'vertical',
        caption = {'blueprint_helper.set_filter_caption'}
    }

    local t = frame.add {type = 'table', column_count = 10}
    t.style.horizontal_spacing = 0
    t.style.vertical_spacing = 0

    local prototypes = game.entity_prototypes

    for _, v in ipairs(get_valid_filters()) do
        local flow = t.add {type = 'flow', caption = v}
        local b =
            flow.add {
            type = 'sprite-button',
            name = filter_element_name,
            sprite = 'entity/' .. v,
            tooltip = prototypes[v].localised_name or v
        }
        Gui.set_data(b, frame)
        b.style = 'slot_button'
    end

    local flow = frame.add {type = 'flow'}

    local close = flow.add {type = 'button', name = filter_table_close_button_name, caption = {'common.close_button'}}
    Gui.set_data(close, frame)

    local clear =
        flow.add {type = 'button', name = filter_table_clear_name, caption = {'blueprint_helper.clear_filters'}}
    Gui.set_data(clear, frame)

    event.player.opened = frame

    Gui.set_data(frame, event.element)
end

local function toggle(event)
    local p_filters = player_filters[event.player_index]
    if not p_filters then
        p_filters = {}
        for i = 1, 9 do
            p_filters[i] = {from = '', to = ''}
        end
        player_filters[event.player_index] = p_filters
    end

    local player = event.player
    local gui = player.gui
    local left = gui.left
    local main_frame = left[main_frame_name]
    local main_button = gui.top[main_button_name]

    if main_frame and main_frame.valid then
        local filters = Gui.get_data(main_frame)

        for i, f in pairs(filters) do
            p_filters[i].from = f.from.parent.caption
            p_filters[i].to = f.to.parent.caption
        end

        Gui.destroy(main_frame)

        if player.opened_gui_type == defines.gui_type.custom then
            local opened = player.opened
            if opened and opened.valid and opened.name == filters_table_name then
                Gui.remove_data_recursively(opened)
                opened.destroy()
            end
        end

        main_button.style = 'icon_button'
    else
        main_button.style = 'selected_slot_button'
        local style = main_button.style
        style.width = 38
        style.height = 38

        main_frame =
            left.add {
            type = 'frame',
            name = main_frame_name,
            direction = 'vertical',
            caption = {'blueprint_helper.tooltip'}
        }
        local scroll_pane =
            main_frame.add {type = 'scroll-pane', direction = 'vertical', vertical_scroll_policy = 'auto'}
        scroll_pane.style.maximal_height = 500

        -- Flipper.

        local flipper_frame =
            scroll_pane.add {type = 'frame', caption = {'blueprint_helper.flipper_caption'}, direction = 'vertical'}
        flipper_frame.style.minimal_width = minimal_width

        local label =
            flipper_frame.add {
            type = 'label',
            caption = {'blueprint_helper.flipper_label'}
        }
        label.style.single_line = false

        local flow = flipper_frame.add {type = 'flow'}

        flow.add {
            type = 'button',
            name = flip_h_button_name,
            caption = {'blueprint_helper.flip_horizontal'}
        }
        flow.add {
            type = 'button',
            name = flip_v_button_name,
            caption = {'blueprint_helper.flip_vertical'}
        }

        -- Converter.

        local filter_frame =
            scroll_pane.add {
            type = 'frame',
            caption = {'blueprint_helper.entity_converter_caption'},
            direction = 'vertical'
        }
        filter_frame.style.minimal_width = minimal_width

        filter_frame.add {
            type = 'label',
            caption = {'blueprint_helper.entity_converter_label'}
        }

        local filter_table = filter_frame.add {type = 'table', column_count = 12}

        local filters = {}

        local prototypes = game.entity_prototypes

        for i = 1, 9 do
            local filler = filter_table.add {type = 'label'}
            filler.style.minimal_width = 16

            local from = p_filters[i].from
            local to = p_filters[i].to

            local from_tooltip, to_tooltip
            if from ~= '' then
                from_tooltip = prototypes[from].localised_name or from
            end
            if to ~= '' then
                to_tooltip = prototypes[to].localised_name or to
            end

            local from_filter =
                filter_table.add({type = 'flow', caption = from}).add {
                type = 'sprite-button',
                name = filter_button_name,
                tooltip = from_tooltip,
                sprite = from ~= '' and 'entity/' .. from or nil
            }
            from_filter.style = 'slot_button'

            filter_table.add {type = 'label', caption = '→'}

            local to_filter =
                filter_table.add({type = 'flow', caption = to}).add {
                type = 'sprite-button',
                name = filter_button_name,
                tooltip = to_tooltip,
                sprite = to ~= '' and 'entity/' .. to or nil
            }
            to_filter.style = 'slot_button'

            table.insert(filters, {from = from_filter, to = to_filter})
        end

        local converter_buttons_flow = filter_frame.add {type = 'flow'}

        local clear_button =
            converter_buttons_flow.add {
            type = 'button',
            name = clear_all_filters_name,
            caption = {'blueprint_helper.clear_filters'}
        }
        Gui.set_data(clear_button, filters)

        local filter_button =
            converter_buttons_flow.add {
            type = 'button',
            name = convert_button_name,
            caption = {'blueprint_helper.convert'}
        }
        Gui.set_data(filter_button, filters)

        main_frame.add {type = 'button', name = main_button_name, caption = {'common.close_button'}}
        Gui.set_data(main_frame, filters)
    end
end

Gui.on_click(main_button_name, toggle)

Gui.on_click(
    flip_h_button_name,
    function(event)
        local player = event.player

        local cursor = getBlueprintCursorStack(player)
        if cursor then
            flip_h(cursor)
        else
            player.print({'blueprint_helper.empty_cursor_error_message'})
        end
    end
)

Gui.on_click(
    flip_v_button_name,
    function(event)
        local player = event.player

        local cursor = getBlueprintCursorStack(player)
        if cursor then
            flip_v(cursor)
        else
            player.print({'blueprint_helper.empty_cursor_error_message'})
        end
    end
)

Gui.on_click(
    filter_button_name,
    function(event)
        if event.button == defines.mouse_button_type.right then
            local element = event.element
            element.sprite = 'utility/pump_cannot_connect_icon'
            element.tooltip = ''
            element.parent.caption = ''
        else
            draw_filters_table(event)
        end
    end
)

Gui.on_click(
    filter_element_name,
    function(event)
        local element = event.element
        local frame = Gui.get_data(element)
        local filter_button = Gui.get_data(frame)

        if filter_button and filter_button.valid then
            filter_button.sprite = element.sprite
            filter_button.tooltip = element.tooltip
            filter_button.parent.caption = element.parent.caption
        end

        Gui.destroy(frame)
    end
)

Gui.on_click(
    filter_table_close_button_name,
    function(event)
        local frame = Gui.get_data(event.element)
        Gui.destroy(frame)
    end
)

Gui.on_click(
    filter_table_clear_name,
    function(event)
        local frame = Gui.get_data(event.element)
        local filter_button = Gui.get_data(frame)

        filter_button.sprite = 'utility/pump_cannot_connect_icon'
        filter_button.tooltip = ''
        filter_button.parent.caption = ''

        Gui.destroy(frame)
    end
)

Gui.on_click(
    clear_all_filters_name,
    function(event)
        local filters = Gui.get_data(event.element)

        for _, filter in ipairs(filters) do
            local from = filter.from
            local to = filter.to

            from.sprite = 'utility/pump_cannot_connect_icon'
            from.tooltip = ''
            from.parent.caption = ''
            to.sprite = 'utility/pump_cannot_connect_icon'
            to.tooltip = ''
            to.parent.caption = ''
        end
    end
)

Gui.on_click(
    convert_button_name,
    function(event)
        local player = event.player

        local cursor = getBlueprintCursorStack(player)
        if not cursor then
            player.print({'blueprint_helper.empty_cursor_error_message'})
            return
        end

        local data = Gui.get_data(event.element)
        local filters = build_filters(data)

        if next(filters) == nil then
            player.print({'blueprint_helper.no_filters_error_message'})
        end

        convert(cursor, filters)
    end
)

Gui.on_custom_close(
    filters_table_name,
    function(event)
        local element = event.element
        Gui.destroy(element)
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_joined_game, player_joined)
