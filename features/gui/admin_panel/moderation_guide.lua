local AdminPanel = require 'features.gui.admin_panel.core'
local ModerationPages = require 'features.gui.admin_panel.moderation_pages'
local Gui = require 'utils.gui'

local main_button_name = Gui.uid_name()
local toggle_button_name = Gui.uid_name()

local pages = AdminPanel.get_pages()
pages[#pages + 1] = {
    type = 'sprite-button',
    sprite = 'utility/custom_tag_icon',
    tooltip = '[font=default-bold]Moderation guide[/font]',
    name = main_button_name,
    auto_toggle = true,
    tags = { admin_only = false },
}

local function make_section(parent, page)
    local section = parent.add { type = 'frame', style = 'bordered_frame', direction = 'vertical' }
    Gui.set_style(section, { use_header_filler = true, top_padding = 8 })

    local flow = section.add { type = 'flow', direction = 'horizontal' }
    Gui.set_style(flow, { horizontally_stretchable = true, horizontal_spacing = 8 })

    local button = flow.add {
        type = 'sprite-button',
        name = toggle_button_name,
        style = 'shortcut_bar_expand_button',
        sprite = 'utility/expand_dots',
        mouse_button_filter = { 'left' },
        auto_toggle = true,
        tooltip = 'Read'
    }
    Gui.set_style(button, { height = 20 })

    local label = flow.add { type = 'label', style = 'caption_label', caption = page.caption }
    Gui.set_style(label, { minimal_width = 80 })
    flow.add { type = 'label', style = 'semibold_label', caption = page.tooltip }

    local frame = flow.add { type = 'frame', direction = 'vertical', style = 'deep_frame_in_shallow_frame_for_description' }
    Gui.set_style(frame, { horizontal_align = 'left', padding = 8, horizontally_stretchable = true })

    frame.add { type = 'label', style = 'tooltip_heading_label_category', caption = '[img=tooltip-category-debug] ' .. page.caption }
    frame.visible = false

    local line = frame.add { type = 'line', style = 'tooltip_category_line' }
    Gui.set_style(line, { left_margin = -11, right_margin = -11, horizontally_stretchable = true })

    if page.draw then
        page.draw(frame)
    end

    return frame
end

local function draw_gui(player)
    local canvas = AdminPanel.get_canvas(player)
    Gui.clear(canvas)

    local sp = canvas.add { type = 'scroll-pane', style = 'naked_scroll_pane', horizontal_scroll_policy = 'never', vertical_scroll_policy = 'auto-and-reserve-space' }
    Gui.set_style(sp, { maximal_height = 700, right_padding = 4 })

    local flow = sp.add { type = 'flow', direction = 'horizontal' }
    Gui.add_pusher(flow)
    flow.add { type = 'sprite-button', sprite = 'utility/empty_armor_slot', style = 'transparent_slot' }
    Gui.add_pusher(flow)
    local title = flow.add { type = 'label', style = 'frame_title', caption = 'Welcome moderator!' }
    Gui.set_style(title, { font_color = { 220, 220, 220 }})
    Gui.add_pusher(flow)
    flow.add { type = 'sprite-button', sprite = 'utility/empty_armor_slot', style = 'transparent_slot' }
    Gui.add_pusher(flow)

    flow = sp.add { type = 'flow', direction = 'horizontal' }
    Gui.add_pusher(flow)
    flow.add { type = 'label', caption = 'Here you will find explanations for every tool available to you.' }
    Gui.add_pusher(flow)

    flow = sp.add { type = 'flow', direction = 'horizontal' }
    Gui.add_pusher(flow)
    flow.add { type = 'label', caption = 'Select a category below to get started.' }
    Gui.add_pusher(flow)

    make_section(sp, ModerationPages.ranks)
    make_section(sp, ModerationPages.moderation)
    make_section(sp, ModerationPages.commands)
    make_section(sp, ModerationPages.server)
    make_section(sp, ModerationPages.resources)
end

Gui.on_click(main_button_name, function(event)
    local player = event.player
    local element = event.element
    if element.toggled then
        AdminPanel.close_all_pages(player)
        event.element.toggled = true
        draw_gui(player)
    else
        Gui.clear(AdminPanel.get_canvas(player))
    end
end)

Gui.on_click(toggle_button_name, function(event)
    local element = event.element
    element.tooltip = element.toggled and 'Close' or 'Read'
    local title = element.parent.children[element.get_index_in_parent() + 1]
    title.visible = not element.toggled
    local tooltip = element.parent.children[element.get_index_in_parent() + 2]
    tooltip.visible = not element.toggled
    local content = element.parent.children[element.get_index_in_parent() + 3]
    content.visible = element.toggled
end)
