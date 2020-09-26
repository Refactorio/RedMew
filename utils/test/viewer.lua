local Gui = require 'utils.gui'
local Builder = require 'utils.test.builder'
local Runner = require 'utils.test.runner'
local Color = require 'resources.color_presets'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Event = require 'utils.event'

local Public = {}

local down_arrow = '▼'
local right_arrow = '►'

local main_frame_name = Gui.uid_name()
local close_main_frame_name = Gui.uid_name()
local module_arrow_name = Gui.uid_name()
local module_label_name = Gui.uid_name()
local test_label_name = Gui.uid_name()
local run_all_button_name = Gui.uid_name()
local run_selected_button_name = Gui.uid_name()
local error_test_box_name = Gui.uid_name()

local selected_modules = {}
local selected_tests = {}

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

local function get_text_box_error()
    local selected_test = next(selected_tests)
    if selected_test then
        return get_test_error(selected_test)
    end

    local selected_module = next(selected_modules)
    if selected_module then
        return get_module_error(selected_module)
    end

    return ''
end

local function set_selected_style(style, selected)
    if selected then
        style.font_color = Color.orange
    else
        style.font_color = Color.white
    end
end

local function set_passed_style(style, passed)
    if passed == true then
        style.font_color = Color.green
    elseif passed == false then
        style.font_color = Color.red
    else
        style.font_color = Color.white
    end
end

local function draw_tests_test(container, test, depth)
    local flow = container.add {type = 'flow'}

    local label = flow.add {type = 'label', name = test_label_name, caption = test.name}
    local label_style = label.style

    local is_selected = selected_tests[test]
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
    local is_selected = selected_modules[module]
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
    local text = get_text_box_error()

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
    local run_all_button = top_flow.add {type = 'button', name = run_all_button_name, caption = 'Run All'}
    local run_selected_button =
        top_flow.add {
        type = 'button',
        name = run_selected_button_name,
        caption = 'Run Selected'
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

local run_module_token =
    Token.register(
    function(module)
        Runner.run_module(module)
    end
)

local run_test_token =
    Token.register(
    function(test)
        Runner.run_test(test)
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

        local is_selected = not selected_modules[module]

        table.clear_table(selected_modules)
        table.clear_table(selected_tests)

        if is_selected then
            selected_modules[module] = is_selected
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

        local is_selected = not selected_tests[test]

        table.clear_table(selected_modules)
        table.clear_table(selected_tests)

        if is_selected then
            selected_tests[test] = is_selected
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
        Task.set_timeout_in_ticks(1, run_module_token, nil)
    end
)

Gui.on_click(
    run_selected_button_name,
    function(event)
        local selected_module = next(selected_modules)
        local selected_test = next(selected_tests)

        if selected_module then
            Task.set_timeout_in_ticks(1, run_module_token, selected_module)
        elseif selected_test then
            Task.set_timeout_in_ticks(1, run_test_token, selected_test)
        else
            return
        end

        local frame = event.player.gui.center[main_frame_name]
        close_main_frame(frame)
    end
)

Event.add(
    Runner.events.tests_run_finished,
    function()
        local player = game.get_player(1)
        Public.open(player)
    end
)

function Public.open(player)
    player = player or game.player
    local center = player.gui.center
    local frame = center[main_frame_name]
    if frame then
        return
    end

    create_main_frame(center)
end

return Public
