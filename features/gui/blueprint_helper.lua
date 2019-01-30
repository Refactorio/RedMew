-- Soft mod version of Blueprint Flipper and Turner https://mods.factorio.com/mods/Marthen/Blueprint_Flip_Turn

local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Game = require 'utils.game'

local player_filters = {}

Global.register(
    {
        player_filters = player_filters
    },
    function(tbl)
        player_filters = tbl.player_filters
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
        ents = cursor.get_blueprint_tiles()
        for i = 1, #ents do
            local dir = ents[i].direction or 0
            ents[i].direction = (12 - dir) % 8
            ents[i].position.y = -ents[i].position.y
        end
        cursor.set_blueprint_tiles(ents)
    end
end

local function flip_h(cursor)
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
        ents = cursor.get_blueprint_tiles()
        for i = 1, #ents do
            local dir = ents[i].direction or 0
            ents[i].direction = (16 - dir) % 8
            ents[i].position.x = -ents[i].position.x
        end
        cursor.set_blueprint_tiles(ents)
    end
end

local function build_filters(data)
    local filters = {}
    for _, filter in pairs(data) do
        local from = filter.from.tooltip
        local to = filter.to.tooltip

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

local valid_filters = {
    'wooden-chest',
    'iron-chest',
    'steel-chest',
    'storage-tank',
    'transport-belt',
    'fast-transport-belt',
    'express-transport-belt',
    'underground-belt',
    'fast-underground-belt',
    'express-underground-belt',
    'splitter',
    'fast-splitter',
    'express-splitter',
    'loader',
    'fast-loader',
    'express-loader',
    'burner-inserter',
    'inserter',
    'long-handed-inserter',
    'fast-inserter',
    'filter-inserter',
    'stack-inserter',
    'stack-filter-inserter',
    'small-electric-pole',
    'medium-electric-pole',
    'big-electric-pole',
    'substation',
    'pipe',
    'pipe-to-ground',
    'pump',
    'curved-rail',
    'straight-rail',
    'train-stop',
    'rail-signal',
    'rail-chain-signal',
    'logistic-chest-active-provider',
    'logistic-chest-passive-provider',
    'logistic-chest-storage',
    'logistic-chest-buffer',
    'logistic-chest-requester',
    'roboport',
    'small-lamp',
    'arithmetic-combinator',
    'decider-combinator',
    'constant-combinator',
    'power-switch',
    'programmable-speaker',
    'boiler',
    'steam-engine',
    'steam-turbine',
    'solar-panel',
    'accumulator',
    'nuclear-reactor',
    'heat-exchanger',
    'heat-pipe',
    'burner-mining-drill',
    'electric-mining-drill',
    'offshore-pump',
    'pumpjack',
    'stone-furnace',
    'steel-furnace',
    'electric-furnace',
    'assembling-machine-1',
    'assembling-machine-2',
    'assembling-machine-3',
    'oil-refinery',
    'chemical-plant',
    'centrifuge',
    'lab',
    'beacon',
    'stone-wall',
    'gate',
    'gun-turret',
    'laser-turret',
    'flamethrower-turret',
    'artillery-turret',
    'radar',
    'rocket-silo'
}

-- Gui implementation.

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
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        return
    end

    player.gui.top.add {name = main_button_name, type = 'sprite-button', sprite = 'item/blueprint'}
end

local function draw_filters_table(event)
    local center = event.player.gui.center

    if center[filters_table_name] then
        return
    end

    local frame = center.add {type = 'frame', name = filters_table_name, direction = 'vertical', caption = 'Set Filter'}

    local t = frame.add {type = 'table', column_count = 10}
    t.style.horizontal_spacing = 0
    t.style.vertical_spacing = 0

    for _, v in ipairs(valid_filters) do
        local flow = t.add {type = 'flow'}
        local b = flow.add {type = 'sprite-button', name = filter_element_name, sprite = 'entity/' .. v, tooltip = v}
        Gui.set_data(b, frame)
        b.style = 'slot_button'
    end

    local flow = frame.add {type = 'flow'}

    local close = flow.add {type = 'button', name = filter_table_close_button_name, caption = 'Close'}
    Gui.set_data(close, frame)

    local clear = flow.add {type = 'button', name = filter_table_clear_name, caption = 'Clear Filter'}
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
    local left = player.gui.left
    local main_frame = left[main_frame_name]

    if main_frame and main_frame.valid then
        local filters = Gui.get_data(main_frame)

        for i, f in pairs(filters) do
            p_filters[i].from = f.from.tooltip
            p_filters[i].to = f.to.tooltip
        end

        Gui.remove_data_recursively(main_frame)
        main_frame.destroy()

        if player.opened_gui_type == defines.gui_type.custom then
            local opened = player.opened
            if opened and opened.valid and opened.name == filters_table_name then
                Gui.remove_data_recursively(opened)
                opened.destroy()
            end
        end
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

        local label =
            flipper_frame.add {
            type = 'label',
            caption = [[
Place blueprint on buttons below to flip blueprint.
Obviously this wont work correctly with refineries or chemical plants.]]
        }
        label.style.single_line = false

        local flow = flipper_frame.add {type = 'flow'}

        flow.add {
            type = 'button',
            name = flip_h_button_name,
            caption = 'Flip Horizontal ⇄'
        }
        flow.add {
            type = 'button',
            name = flip_v_button_name,
            caption = 'Flip Vertical ⇵'
        }

        -- Converter.

        local filter_frame = scroll_pane.add {type = 'frame', caption = 'Entity Converter', direction = 'vertical'}

        filter_frame.add {
            type = 'label',
            -- The empty space is a hacky way to line this frame up with the above frame.
            caption = 'Set filters then place blueprint on convert button to apply filters.          '
        }

        local filter_table = filter_frame.add {type = 'table', column_count = 12}

        local filters = {}

        for i = 1, 9 do
            local filler = filter_table.add {type = 'label'}
            filler.style.minimal_width = 16

            local from_tooltip = p_filters[i].from
            local to_tooltip = p_filters[i].to

            local from_filter =
                filter_table.add({type = 'flow'}).add {
                type = 'sprite-button',
                name = filter_button_name,
                tooltip = from_tooltip,
                sprite = from_tooltip ~= '' and 'entity/' .. from_tooltip or nil
            }
            from_filter.style = 'slot_button'

            filter_table.add {type = 'label', caption = '→'}

            local to_filter =
                filter_table.add({type = 'flow'}).add {
                type = 'sprite-button',
                name = filter_button_name,
                tooltip = to_tooltip,
                sprite = to_tooltip ~= '' and 'entity/' .. to_tooltip or nil
            }
            to_filter.style = 'slot_button'

            table.insert(filters, {from = from_filter, to = to_filter})
        end

        local converter_buttons_flow = filter_frame.add {type = 'flow'}

        local clear_button =
            converter_buttons_flow.add {type = 'button', name = clear_all_filters_name, caption = 'Clear Filters'}
        Gui.set_data(clear_button, filters)

        local filter_button =
            converter_buttons_flow.add {type = 'button', name = convert_button_name, caption = 'Convert'}
        Gui.set_data(filter_button, filters)

        main_frame.add {type = 'button', name = main_button_name, caption = 'Close'}
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
            player.print('Click the button with a blueprint or blueprint book.')
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
            player.print('Click the button with a blueprint or blueprint book.')
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
        end

        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_click(
    filter_table_close_button_name,
    function(event)
        local frame = Gui.get_data(event.element)

        Gui.remove_data_recursively(frame)
        frame.destroy()
    end
)

Gui.on_click(
    filter_table_clear_name,
    function(event)
        local frame = Gui.get_data(event.element)
        local filter_button = Gui.get_data(frame)

        filter_button.sprite = 'utility/pump_cannot_connect_icon'
        filter_button.tooltip = ''

        Gui.remove_data_recursively(frame)
        frame.destroy()
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
            to.sprite = 'utility/pump_cannot_connect_icon'
            to.tooltip = ''
        end
    end
)

Gui.on_click(
    convert_button_name,
    function(event)
        local player = event.player

        local cursor = getBlueprintCursorStack(player)
        if not cursor then
            player.print('Click the button with a blueprint or blueprint book.')
            return
        end

        local data = Gui.get_data(event.element)
        local filters = build_filters(data)

        if next(filters) == nil then
            player.print('No filters have been set')
        end

        convert(cursor, filters)
    end
)

Gui.on_custom_close(
    filters_table_name,
    function(event)
        local element = event.element
        Gui.remove_data_recursively(element)
        element.destroy()
    end
)

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_joined_game, player_joined)
