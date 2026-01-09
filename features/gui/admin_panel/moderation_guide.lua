local AdminPanel = require 'features.gui.admin_panel.core'
local Event = require 'utils.event'
local ModerationPages = require 'features.gui.admin_panel.moderation_pages'
local Gui = require 'utils.gui'

local main_button_name = Gui.uid_name()
local toggle_button_name = Gui.uid_name()
local secondary_window_close_name = Gui.uid_name()

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
        tooltip = 'Open/close ' .. page.index .. ' window',
        tags = { index = page.index },
    }
    Gui.set_style(button, { height = 20 })

    local label = flow.add { type = 'label', style = 'caption_label', caption = page.caption }
    Gui.set_style(label, { minimal_width = 80 })
    flow.add { type = 'label', style = 'semibold_label', caption = page.tooltip }

    return flow
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

local function get_page_position(key)
    local i = 1
    for k, _ in pairs(ModerationPages) do
        if k == key then
            return i
        end
        i = i + 1
    end
    return nil -- key not found
end

local function create_closable_frame(player, page)
    local frame = player.gui.screen[page.name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    frame = player.gui.screen.add { type = 'frame', name = page.name, direction = 'vertical', style = 'frame' }
    frame.location = AdminPanel.get_main_frame_location(player, {
        x = get_page_position(page.index) *  64,
        y = get_page_position(page.index) * -32
    })
    Gui.set_style(frame, {
        horizontally_stretchable = true,
        vertically_stretchable = true,
        maximal_width = page.size[1],
        maximal_height = page.size[2],
        top_padding = 8,
        bottom_padding = 8,
    })

    do -- title
        local title_flow = frame.add { type = 'flow', direction = 'horizontal' }
        Gui.set_style(title_flow, { horizontal_spacing = 8, vertical_align = 'center', bottom_padding = 4 })

        local label = title_flow.add { type = 'label', caption = page.caption, style = 'frame_title' }
        label.drag_target = frame

        local dragger = title_flow.add { type = 'empty-widget', style = 'draggable_space_header' }
        dragger.drag_target = frame
        Gui.set_style(dragger,  {
            height = 24,
            vertically_stretchable = false,
            horizontally_stretchable = true,
        })

        local close_button = title_flow.add {
            type = 'sprite-button',
            name = secondary_window_close_name,
            sprite = 'utility/close',
            clicked_sprite = 'utility/close_black',
            style = 'close_button',
            tooltip = 'Close',
        }
        Gui.set_data(close_button, { frame = frame })
    end

    if page.draw then
        page.draw(frame)
    end

    return frame
end

Gui.on_click(secondary_window_close_name, function(event)
    local elem_data = Gui.get_data(event.element)
    Gui.destroy(elem_data.frame)
end)

Gui.on_click(toggle_button_name, function(event)
    local player = event.player
    local page = ModerationPages[event.element.tags.index]
    local frame = player.gui.screen[page.name]

    if frame then
        Gui.destroy(frame)
    else
        create_closable_frame(player, page)
    end
end)

Event.add(AdminPanel.events.on_admin_gui_closed, function(event)
    local screen = event.player.gui.screen
    for _, page in pairs(ModerationPages) do
        local window = screen[page.name]
        if window then
            Gui.destroy(window)
        end
    end
end)
