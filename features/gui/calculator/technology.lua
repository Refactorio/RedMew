-- This feature adds a command "/calculator-technology" that shows a small popup
-- with the breakdown cost to research target technology.
-- made by RedRafe
-- ======================================================= --

local Command = require 'utils.command'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Ranks = require 'resources.ranks'
local Global = require 'utils.global'
local History = require 'utils.history'

local history = {}
local toggled = {}

Global.register({
    history = history,
    toggled = toggled,
}, function(tbl)
    history = tbl.history
    toggled = tbl.toggled
end)

local function get_history(player_index)
    local h = history[player_index]
    if not h then
        h = History.new()
        history[player_index] = h
    end
    return h
end

local function set_history(player_index, technology_name)
    local h = get_history(player_index)
    if technology_name == nil then
        h:clear()
    elseif prototypes.technology[technology_name] ~= nil then
        h:add(technology_name)
    end
end

local function dict_to_array(dict)
    local array = {}
    for k, v in pairs(dict) do
        table.insert(array, { name = k, count = v })
    end
    return array
end

local function safe_div(a, b)
    return b <= 0 and 0 or a / b
end

local function sort_lab_input(a, b)
    local a_order = prototypes.item[a.name].order
    local b_order = prototypes.item[b.name].order
    return a_order < b_order
end

---@param force LuaForce
---@param technology_name string
local function get_research_info(force, technology_name)
    if (technology_name == nil) or (force.technologies[technology_name] == nil) then
        return {
            cost_breakdown = {},
            research_path = {},
        }
    end

    local tech = force.technologies[technology_name]
    local cost_breakdown = {
        -- sci pack name/icon
        -- relative count
        -- absolute count
        -- progress
    }
    local research_path = {
        -- technology name/icon
        -- ingredients w/ count,
        -- order ?
        -- localised_name
    }

    local relative = {}
    local absolute = {}
    local seen = {}

    ---@param technology LuaTechnology
    local function compute_cost(technology)
        if seen[technology.name] then
            return
        end

        seen[technology.name] = true

        local ingredients = {}
        local absolute_cost = technology.research_unit_count or 0
        local relative_cost = technology.researched and 0 or absolute_cost

        for _, ingredient in pairs(technology.research_unit_ingredients) do
            ingredients[ingredient.name] = absolute_cost * ingredient.amount
            absolute[ingredient.name] = (absolute[ingredient.name] or 0) + absolute_cost * ingredient.amount
            relative[ingredient.name] = (relative[ingredient.name] or 0) + relative_cost * ingredient.amount
        end

        ingredients = dict_to_array(ingredients)
        table.sort(ingredients, sort_lab_input)

        if not technology.researched then
            table.insert(research_path, {
                name = technology.name,
                localised_name = technology.localised_name,
                ingredients = ingredients,
            })
        end

        for _, prereq in pairs(technology.prerequisites) do
            compute_cost(prereq)
        end
    end

    compute_cost(tech)

    local tot_abs, tot_rel = 0, 0
    for ingredient, count in pairs(absolute) do
        local c = {
            name = ingredient,
            relative = relative[ingredient],
            absolute = count,
            progress = 1 - safe_div(relative[ingredient], count),
            localised_name = prototypes.item[ingredient].localised_name,
        }
        table.insert(cost_breakdown, c)
        tot_abs = tot_abs + c.absolute
        tot_rel = tot_rel + c.relative
    end

    table.sort(cost_breakdown, sort_lab_input)
    table.sort(research_path, function(a, b)
        return a.name < b.name
    end)

    return {
        research_path = research_path,
        cost_breakdown = cost_breakdown,
        average = {
            absolute = tot_abs,
            relative = tot_rel,
            progress = 1 - safe_div(tot_rel, tot_abs),
        },
    }
end

-- == GUI =====================================================================

local main_frame_name = Gui.uid_name()
local close_button_name = Gui.uid_name()
local history_back_button_name = Gui.uid_name()
local history_forward_button_name = Gui.uid_name()
local select_button_name = Gui.uid_name()
local toggle_list_button_name = Gui.uid_name()
local shortcut_button_name = Gui.uid_name()
local on_technologies, off_technologies = '▼  Technologies', '▲  Technologies'

local function get_main_frame(player)
    local frame = player.gui.screen[main_frame_name]
    if frame and frame.valid then
        Gui.clear(frame)
        return frame
    end

    frame = player.gui.screen.add {
        type = 'frame',
        name = main_frame_name,
        direction = 'vertical',
        style = 'frame',
    }
    Gui.set_style(frame, {
        horizontally_stretchable = true,
        vertically_stretchable = true,
        maximal_height = 600,
        natural_width = 482,
        top_padding = 8,
        bottom_padding = 8,
    })
    Gui.set_data(frame, { frame = frame })

    frame.force_auto_center()
    player.opened = frame
    return frame
end

local function show_ingredients(parent, ingredients)
    local flow = parent.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(flow, { horizontally_stretchable = true })

    for _, ingredient in pairs(ingredients) do
        local b = flow.add {
            type = 'sprite-button',
            style = 'slot',
            number = ingredient.count,
            sprite = 'item/' .. ingredient.name,
            tooltip = prototypes.item[ingredient.name].localised_name,
        }
        Gui.set_style(b, { size = 32, font = 'default-small-semibold' })
    end
end

local function shortcut_button(parent, info)
    local b = parent
        .add { type = 'flow' }
        .add {
            type = 'sprite-button',
            style = 'transparent_slot',
            sprite = 'technology/' .. info.name,
            name = shortcut_button_name,
            tags = { name = info.name },
            tooltip = {'', '[color=0.5,0.8,0.94][font=var]Click[/font][/color] to go to this technology\'s breakdown'}
        }
    Gui.set_style(b, { size = 32 })
    return b
end

local function progressbar(parent, info)
    local p = parent.add {
        type = 'progressbar',
        value = info.progress,
        tooltip = ('%.2f %%'):format(info.progress * 100),
        style = 'achievement_progressbar',
    }
    Gui.set_style(p, { width = 80 })
    return p
end

local function draw(player)
    local frame = get_main_frame(player)
    local data = Gui.get_data(frame)
    local h = get_history(player.index)
    local technology_name = h:get()

    local info = get_research_info(player.force, technology_name)

    do --- title
        local flow = frame.add { type = 'flow', direction = 'horizontal' }
        Gui.set_style(flow, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

        local label = flow.add { type = 'label', caption = 'Research calculator', style = 'frame_title' }
        label.drag_target = frame

        Gui.add_dragger(flow, frame)

        local history_flow = flow.add { type = 'flow', direction = 'horizontal' }
        Gui.set_style(history_flow, { horizontal_spacing = 0, padding = 0 })

        local backward = history_flow.add {
            type = 'sprite-button',
            name = history_back_button_name,
            sprite = 'utility/backward_arrow',
            clicked_sprite = 'utility/backward_arrow_black',
            style = 'close_button',
            tooltip = 'Back',
        }
        backward.enabled = h:peek_previous() ~= nil

        local forward = history_flow.add {
            type = 'sprite-button',
            name = history_forward_button_name,
            sprite = 'utility/forward_arrow',
            clicked_sprite = 'utility/forward_arrow_black',
            style = 'close_button',
            tooltip = 'Forward',
        }
        forward.enabled = h:peek_next() ~= nil

        local close_button = flow.add {
            type = 'sprite-button',
            name = close_button_name,
            sprite = 'utility/close',
            clicked_sprite = 'utility/close_black',
            style = 'close_button',
            tooltip = { 'gui.close-instruction' },
        }
        Gui.set_data(close_button, { frame = frame })
    end
    do --- body
        local body = frame.add { type = 'frame', style = 'inside_shallow_frame_packed', direction = 'vertical' }.add { type = 'scroll-pane', style = 'naked_scroll_pane' }
        Gui.set_style(body.parent, { horizontally_stretchable = true, top_padding = 8, left_padding = 8, bottom_padding = 8 })
        Gui.set_style(body, { right_padding = 8 })

        do --- Technology selection
            local flow = body.add { type = 'frame', style = 'bordered_frame' }.add { type = 'flow', direction = 'horizontal' }
            flow.add { type = 'label', caption = 'Select technology', style = 'caption_label' }

            Gui.add_pusher(flow, 'horizontal')

            local select_button = flow.add {
                type = 'choose-elem-button',
                name = select_button_name,
                style = 'slot_button_in_shallow_frame',
                elem_type = 'technology',
                technology = technology_name,
            }
            data.select_button = select_button
            Gui.set_data(select_button, data)
        end

        do --- Technology cost breakdown
            local breakdown = body.add {
                type = 'table',
                style = 'finished_game_table',
                column_count = 4,
                draw_horizontal_line_after_headers = false,
            }
            data.breakdown = breakdown
            breakdown.style.column_alignments[2] = 'center'
            breakdown.style.column_alignments[3] = 'right'
            breakdown.style.column_alignments[4] = 'right'
            Gui.set_style(breakdown, { horizontally_stretchable = true })

            for _, title in pairs({
                'Science',
                'Progress',
                'Relative',
                'Absolute',
            }) do
                breakdown.add { type = 'label', caption = title, style = 'bold_label' }
            end
            for _, c in pairs(info.cost_breakdown) do
                breakdown.add { type = 'label', caption = { '', '[img=item/' .. c.name .. '] ', c.localised_name } }
                progressbar(breakdown, c)
                breakdown.add { type = 'label', caption = c.relative }
                breakdown.add { type = 'label', caption = c.absolute }
            end

            local avg = info.average
            if avg then
                breakdown.add { type = 'label', caption = ('Completion %d %%'):format(avg.progress * 100), style = 'info_label' }
                progressbar(breakdown, avg)
                breakdown.add { type = 'label', caption = avg.relative }
                breakdown.add { type = 'label', caption = avg.absolute }
            end

            breakdown.visible = (technology_name ~= nil)
        end

        do --- Technology research path
            local label = body.add {
                type = 'label',
                style = 'bold_label',
                caption = toggled[player.index] and on_technologies or off_technologies,
                name = toggle_list_button_name,
                tooltip = 'Hide/Show technologies list',
            }
            data.label = label
            Gui.set_data(label, data)

            local deep = body.add { type = 'frame', style = 'deep_frame_in_shallow_frame_for_description', direction = 'vertical' }
            Gui.set_style(deep, { padding = 0, minimal_height = 4 })

            local list = deep.add { type = 'scroll-pane', vertical_scroll_policy = 'never' }.add { type = 'table', style = 'table_with_selection', column_count = 3 }
            Gui.set_style(list.parent, { horizontally_squashable = false })

            list.visible = toggled[player.index] or false
            data.list = list
            Gui.set_data(list, data)

            for _, t in pairs(info.research_path) do
                shortcut_button(list, t)
                list.add { type = 'label', caption = t.localised_name }
                show_ingredients(list, t.ingredients)
            end
        end
    end
end

Gui.on_click(close_button_name, function(event)
    Gui.destroy(Gui.get_data(event.element).frame)
end)

Gui.on_custom_close(main_frame_name, function(event)
    Gui.destroy(event.element)
end)

Gui.on_click(history_back_button_name, function(event)
    local h = get_history(event.player_index)
    h:previous()
    draw(event.player)
end)

Gui.on_click(history_forward_button_name, function(event)
    local h = get_history(event.player_index)
    h:next()
    draw(event.player)
end)

Gui.on_elem_changed(select_button_name, function(event)
    set_history(event.player_index, event.element.elem_value)
    draw(event.player)
end)

Gui.on_click(toggle_list_button_name, function(event)
    local data = Gui.get_data(event.element)
    data.list.visible = not data.list.visible
    toggled[event.player_index] = data.list.visible
    data.label.caption = data.list.visible and on_technologies or off_technologies
end)

Gui.on_click(shortcut_button_name, function(event)
    if get_history(event.player_index):get() == event.element.tags.name then
        return
    end
    set_history(event.player_index, event.element.tags.name)
    draw(event.player)
end)

-- == COMMANDS ================================================================

Command.add('calculator-technology', {
    description = {'command_description.calculator_tech'},
    arguments = { 'technology' },
    default_values = { technology = '' },
    allowed_by_server = false,
    required_rank = Ranks.guest,
    capture_excess_arguments = true,
}, function(arguments, player, _)
    set_history(player.index, arguments.technology)
    draw(player)
end)

Command.add('calculator-technology-for-player', {
    description = {'command_description.calculator_tech_player'},
    arguments = { 'technology', 'player' },
    allowed_by_server = false,
    required_rank = Ranks.moderator,
    capture_excess_arguments = true,
}, function(arguments, player, _)
    local target_player = game.get_player(arguments.player)
    if not player then
        player.print('Invalid <player>')
        return
    end
    if prototypes.technology[arguments.technology] == nil then
        player.print('Invalid <technology>')
        return
    end

    set_history(player.index, arguments.technology)
    draw(player)

    if player ~= target_player then
        set_history(target_player.index, arguments.technology)
        draw(target_player)
    end
end)

Event.add(defines.events.on_player_removed, function(event)
    history[event.player_index] = nil
    toggled[event.player_index] = nil
end)
