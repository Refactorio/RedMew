local Gui = require 'utils.gui'
local Builder = require 'utils.test.builder'
local Runner = require 'utils.test.runner'
local Color = require 'resources.color_presets'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Event = require 'utils.event'
local Global = require 'utils.global'

local Public = {}

local info_type_test = {}
local info_type_module = {}

local down_arrow = '▼'
local right_arrow = '►'
local color_success = {g = 1}
local color_failure = {r = 1}
local color_selected = Color.orange
local color_default = Color.white

local main_frame_name = Gui.uid_name()
local close_main_frame_name = Gui.uid_name()
local module_arrow_name = Gui.uid_name()
local module_label_name = Gui.uid_name()
local test_label_name = Gui.uid_name()
local run_all_button_name = Gui.uid_name()
local run_selected_button_name = Gui.uid_name()
local stop_on_error_checkbox_name = Gui.uid_name()
local error_test_box_name = Gui.uid_name()

local selected_test_info_by_player_index = {}
local stop_on_first_error_by_player_index = {}

Global.register(
    {
        selected_test_info_by_player_index = selected_test_info_by_player_index,
        stop_on_first_error_by_player_index = stop_on_first_error_by_player_index
    },
    function(tbl)
        selected_test_info_by_player_index = tbl.selected_test_info_by_player_index
        stop_on_first_error_by_player_index = tbl.stop_on_first_error_by_player_index
    end
)

local function get_module_state(module)
    local passed = module.passed
    if passed == false or module.startup_error or module.teardown_error then
        return false
    end

    return passed
end

local function get_test_error(test)
    return test.error or ''
end

local function get_module_error(module)
    local errors = {}
    if module.startup_error then
        errors[#errors + 1] = 'startup error: '
        errors[#errors + 1] = module.startup_error
        errors[#errors + 1] = '\n\n'
    end
    if module.teardown_error then
        errors[#errors + 1] = 'teardown error: '
        errors[#errors + 1] = module.teardown_error
    end

    return table.concat(errors)
end

local function get_text_box_error(player_index)
    local test_info = selected_test_info_by_player_index[player_index]
    if test_info == nil then
        return ''
    end

    local info_type = test_info.type

    if info_type == info_type_test then
        return get_test_error(test_info.test)
    elseif info_type == info_type_module then
        return get_module_error(test_info.module)
    end
end

local function set_selected_style(style, selected)
    if selected then
        style.font_color = color_selected
    else
        style.font_color = color_default
    end
end

local function set_passed_style(style, passed)
    if passed == true then
        style.font_color = color_success
    elseif passed == false then
        style.font_color = color_failure
    else
        style.font_color = color_default
    end
end

local function is_test_selected(test, player_index)
    local info = selected_test_info_by_player_index[player_index]
    if not info then
        return false
    end

    local info_test = info.test
    if not info_test then
        return false
    end

    return info_test.id == test.id
end

local function is_module_selected(module, player_index)
    local info = selected_test_info_by_player_index[player_index]
    if not info then
        return false
    end

    local info_module = info.module
    if not info_module then
        return false
    end

    return info_module.id == module.id
end

local function draw_tests_test(container, test, depth)
    local flow = container.add {type = 'flow'}

    local label = flow.add {type = 'label', name = test_label_name, caption = test.name}
    local label_style = label.style

    local is_selected = is_test_selected(test, container.player_index)
    set_selected_style(label_style, is_selected)
    if not is_selected then
        set_passed_style(label_style, test.passed)
    end

    label_style.left_margin = depth * 15 + 10
    Gui.set_data(label, {test = test, container = container})
end

local function draw_tests_module(container, module)
    local caption = {module.name or 'All Tests', ' (', module.count, ')'}
    caption = table.concat(caption)

    local flow = container.add {type = 'flow'}
    local arrow =
        flow.add {
        type = 'label',
        name = module_arrow_name,
        caption = module.is_open and down_arrow or right_arrow
    }
    arrow.style.left_margin = module.depth * 15
    Gui.set_data(arrow, {module = module, container = container})

    local label = flow.add {type = 'label', name = module_label_name, caption = caption}

    local label_style = label.style
    local is_selected = is_module_selected(module, container.player_index)
    set_selected_style(label_style, is_selected)
    if not is_selected then
        set_passed_style(label_style, get_module_state(module))
    end

    Gui.set_data(label, {module = module, container = container})

    if not module.is_open then
        return
    end

    for _, child in pairs(module.children) do
        draw_tests_module(container, child)
    end

    for _, test in pairs(module.tests) do
        draw_tests_test(container, test, module.depth + 1)
    end
end

local function redraw_tests(container)
    Gui.clear(container)

    local root_module = Builder.get_root_modules()
    draw_tests_module(container, root_module)
end

local function draw_tests(container)
    local scroll_pane =
        container.add {
        type = 'scroll-pane',
        horizontal_scroll_policy = 'auto-and-reserve-space',
        vertical_scroll_policy = 'auto-and-reserve-space'
    }
    local scroll_pane_style = scroll_pane.style
    scroll_pane_style.horizontally_stretchable = true
    scroll_pane_style.height = 350

    local list = scroll_pane.add {type = 'flow', direction = 'vertical'}

    redraw_tests(list)
end

local function draw_error_text_box(container)
    local text = get_text_box_error(container.player_index)

    local text_box = container.add {type = 'text-box', name = error_test_box_name, text = text}
    local style = text_box.style
    style.vertically_stretchable = true
    style.horizontally_stretchable = true
    style.maximal_width = 800
    return text_box
end

local function create_main_frame(center)
    local frame = center.add {type = 'frame', name = main_frame_name, caption = 'Test Runner', direction = 'vertical'}
    local frame_style = frame.style
    frame_style.width = 800
    frame_style.height = 600

    local top_flow = frame.add {type = 'flow', direction = 'horizontal'}
    top_flow.add {type = 'button', name = run_all_button_name, caption = 'Run All'}
    top_flow.add {
        type = 'button',
        name = run_selected_button_name,
        caption = 'Run Selected'
    }
    top_flow.add {
        type = 'checkbox',
        name = stop_on_error_checkbox_name,
        caption = 'Stop on first error',
        state = stop_on_first_error_by_player_index[center.player_index] or false
    }

    draw_tests(frame)

    local error_text_box = draw_error_text_box(frame)
    Gui.set_data(frame, {error_text_box = error_text_box})

    local close_button = frame.add {type = 'button', name = close_main_frame_name, caption = 'Close'}
    Gui.set_data(close_button, frame)
end

local function close_main_frame(frame)
    Gui.destroy(frame)
end

local function get_error_text_box(player)
    local frame = player.gui.center[main_frame_name]
    local frame_data = Gui.get_data(frame)
    return frame_data.error_text_box
end

local function make_options(player_index)
    return {stop_on_first_error = stop_on_first_error_by_player_index[player_index]}
end

local run_module_token =
    Token.register(
    function(data)
        Runner.run_module(data.module, data.player, data.options)
    end
)

local run_test_token =
    Token.register(
    function(data)
        Runner.run_test(data.test, data.player, data.options)
    end
)

Gui.on_click(
    close_main_frame_name,
    function(event)
        local element = event.element
        local frame = Gui.get_data(element)
        close_main_frame(frame)
    end
)

Gui.on_click(
    module_arrow_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)
        local module = data.module
        local container = data.container

        module.is_open = not module.is_open
        redraw_tests(container)
    end
)

Gui.on_click(
    module_label_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)
        local module = data.module
        local container = data.container
        local player_index = event.player_index

        local is_selected = not is_module_selected(module, player_index)
        selected_test_info_by_player_index[player_index] = nil

        if is_selected then
            selected_test_info_by_player_index[player_index] = {type = info_type_module, module = module}
        end

        local error_text_box = get_error_text_box(event.player)
        if is_selected then
            error_text_box.text = get_module_error(module)
        else
            error_text_box.text = ''
        end

        redraw_tests(container)
    end
)

Gui.on_click(
    test_label_name,
    function(event)
        local element = event.element
        local data = Gui.get_data(element)
        local test = data.test
        local container = data.container
        local player_index = event.player_index

        local is_selected = not is_test_selected(test, player_index)
        selected_test_info_by_player_index[player_index] = nil

        if is_selected then
            selected_test_info_by_player_index[player_index] = {type = info_type_test, test = test}
        end

        local error_text_box = get_error_text_box(event.player)
        if is_selected then
            error_text_box.text = get_test_error(test)
        else
            error_text_box.text = ''
        end

        redraw_tests(container)
    end
)

Gui.on_click(
    run_all_button_name,
    function(event)
        local frame = event.player.gui.center[main_frame_name]
        close_main_frame(frame)

        local options = make_options(event.player_index)
        Task.set_timeout_in_ticks(1, run_module_token, {module = nil, player = event.player, options = options})
    end
)

Gui.on_click(
    run_selected_button_name,
    function(event)
        local test_info = selected_test_info_by_player_index[event.player_index]
        if test_info == nil then
            return
        end

        local options = make_options(event.player_index)

        local info_type = test_info.type
        if info_type == info_type_module then
            Task.set_timeout_in_ticks(
                1,
                run_module_token,
                {module = test_info.module, player = event.player, options = options}
            )
        elseif info_type == info_type_test then
            Task.set_timeout_in_ticks(
                1,
                run_test_token,
                {test = test_info.test, player = event.player, options = options}
            )
        else
            return
        end

        local frame = event.player.gui.center[main_frame_name]
        close_main_frame(frame)
    end
)

Gui.on_checked_state_changed(
    stop_on_error_checkbox_name,
    function(event)
        stop_on_first_error_by_player_index[event.player_index] = event.element.state or nil
    end
)

Event.add(
    Runner.events.tests_run_finished,
    function(event)
        Public.open(event.player)
    end
)

function Public.open(player)
    local center = player.gui.center
    local frame = center[main_frame_name]
    if frame then
        return
    end

    create_main_frame(center)
end

return Public
