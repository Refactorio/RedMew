local Gui = require 'utils.gui'
local Color = require 'resources.color_presets'
local Model = require 'features.gui.debug.model'

local dump_function = Model.dump_function
local loaded = _G.package.loaded

local Public = {}

local ignore = {
    _G = true,
    package = true,
    coroutine = true,
    table = true,
    string = true,
    bit32 = true,
    math = true,
    debug = true,
    serpent = true,
    ['utils.math'] = true,
    util = true,
    ['utils.inspect'] = true,
    ['mod-gui'] = true
}

local file_label_name = Gui.uid_name()
local left_panel_name = Gui.uid_name()
local breadcrumbs_name = Gui.uid_name()
local top_panel_name = Gui.uid_name()
local variable_label_name = Gui.uid_name()
local text_box_name = Gui.uid_name()

Public.name = 'package'

function Public.show(container)
    local main_flow = container.add {type = 'flow', direction = 'horizontal'}

    local left_panel = main_flow.add {type = 'scroll-pane', name = left_panel_name}
    local left_panel_style = left_panel.style
    left_panel_style.width = 300

    for name, file in pairs(loaded) do
        if not ignore[name] then
            local file_label =
                left_panel.add({type = 'flow'}).add {type = 'label', name = file_label_name, caption = name}
            Gui.set_data(file_label, file)
        end
    end

    local right_flow = main_flow.add {type = 'flow', direction = 'vertical'}

    local breadcrumbs = right_flow.add {type = 'label', name = breadcrumbs_name}

    local top_panel = right_flow.add {type = 'scroll-pane', name = top_panel_name}
    local top_panel_style = top_panel.style
    top_panel_style.height = 200
    top_panel_style.maximal_width = 1000
    top_panel_style.horizontally_stretchable = true

    local text_box = right_flow.add {type = 'text-box', name = text_box_name}
    text_box.read_only = true
    text_box.selectable = true

    local text_box_style = text_box.style
    text_box_style.vertically_stretchable = true
    text_box_style.horizontally_stretchable = true
    text_box_style.maximal_width = 1000
    text_box_style.maximal_height = 1000

    local data = {
        left_panel = left_panel,
        breadcrumbs = breadcrumbs,
        top_panel = top_panel,
        text_box = text_box,
        selected_file_label = nil,
        selected_variable_label = nil
    }

    Gui.set_data(left_panel, data)
    Gui.set_data(top_panel, data)
end

Gui.on_click(
    file_label_name,
    function(event)
        local element = event.element
        local file = Gui.get_data(element)

        local left_panel = element.parent.parent
        local data = Gui.get_data(left_panel)

        local selected_file_label = data.selected_file_label

        if selected_file_label then
            selected_file_label.style.font_color = Color.white
        end

        element.style.font_color = Color.orange
        data.selected_file_label = element

        local top_panel = data.top_panel
        local text_box = data.text_box

        Gui.clear(top_panel)

        local file_type = type(file)

        if file_type == 'table' then
            for k, v in pairs(file) do
                local label =
                    top_panel.add({type = 'flow'}).add {type = 'label', name = variable_label_name, caption = k}
                Gui.set_data(label, v)
            end
        elseif file_type == 'function' then
            text_box.text = dump_function(file)
        else
            text_box.text = tostring(file)
        end
    end
)

Gui.on_click(
    variable_label_name,
    function(event)
        local element = event.element
        local variable = Gui.get_data(element)

        local top_panel = element.parent.parent
        local data = Gui.get_data(top_panel)
        local text_box = data.text_box

        local variable_type = type(variable)

        if variable_type == 'table' then
            Gui.clear(top_panel)
            for k, v in pairs(variable) do
                local label =
                    top_panel.add({type = 'flow'}).add {type = 'label', name = variable_label_name, caption = k}
                Gui.set_data(label, v)
            end
            return
        end

        local selected_label = data.selected_variable_label

        if selected_label and selected_label.valid then
            selected_label.style.font_color = Color.white
        end

        element.style.font_color = Color.orange
        data.selected_variable_label = element

        if variable_type == 'function' then
            text_box.text = dump_function(variable)
        else
            text_box.text = tostring(variable)
        end
    end
)

return Public
