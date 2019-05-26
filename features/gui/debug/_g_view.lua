local Gui = require 'utils.gui'
local Model = require 'features.gui.debug.model'
local Color = require 'resources.color_presets'

local dump = Model.dump

local Public = {}

local ignore = {
    _G = true,
    assert = true,
    collectgarbage = true,
    error = true,
    getmetatable = true,
    ipairs = true,
    load = true,
    loadstring = true,
    next = true,
    pairs = true,
    pcall = true,
    print = true,
    rawequal = true,
    rawlen = true,
    rawget = true,
    rawset = true,
    select = true,
    setmetatable = true,
    tonumber = true,
    tostring = true,
    type = true,
    xpcall = true,
    _VERSION = true,
    module = true,
    require = true,
    package = true,
    unpack = true,
    table = true,
    string = true,
    bit32 = true,
    math = true,
    debug = true,
    serpent = true,
    log = true,
    table_size = true,
    global = true,
    remote = true,
    commands = true,
    settings = true,
    rcon = true,
    script = true,
    util = true,
    mod_gui = true,
    game = true,
    rendering = true
}

local header_name = Gui.uid_name()
local left_panel_name = Gui.uid_name()
local right_panel_name = Gui.uid_name()

Public.name = '_G'

function Public.show(container)
    local main_flow = container.add {type = 'flow', direction = 'horizontal'}

    local left_panel = main_flow.add {type = 'scroll-pane', name = left_panel_name}
    local left_panel_style = left_panel.style
    left_panel_style.width = 300

    for key, value in pairs(_G) do
        if not ignore[key] then
            local header =
                left_panel.add({type = 'flow'}).add {type = 'label', name = header_name, caption = tostring(key)}
            Gui.set_data(header, value)
        end
    end

    local right_panel = main_flow.add {type = 'text-box', name = right_panel_name}
    right_panel.read_only = true
    right_panel.selectable = true

    local right_panel_style = right_panel.style
    right_panel_style.vertically_stretchable = true
    right_panel_style.horizontally_stretchable = true
    right_panel_style.maximal_width = 1000
    right_panel_style.maximal_height = 1000

    Gui.set_data(left_panel, {right_panel = right_panel, selected_header = nil})
end

Gui.on_click(
    header_name,
    function(event)
        local element = event.element
        local value = Gui.get_data(element)

        local left_panel = element.parent.parent
        local left_panel_data = Gui.get_data(left_panel)
        local right_panel = left_panel_data.right_panel
        local selected_header = left_panel_data.selected_header

        if selected_header then
            selected_header.style.font_color = Color.white
        end

        element.style.font_color = Color.orange
        left_panel_data.selected_header = element

        local content = dump(value)
        right_panel.text = content
    end
)

return Public
