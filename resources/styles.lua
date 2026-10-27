local Public = {}

function Public.default_close(style)
    style.height = 28
    style.font = 'default-semibold'
    style.font_color = {0, 0, 0}
end

Public.default_top_element = {
    name = 'frame_button',
    style = {
        font_color = { 165, 165, 165 },
        font = 'heading-2',
        minimal_height = 40,
        maximal_height = 40,
        minimal_width = 40,
        padding = -2,
    }
}

Public.default_left_element = {
    style = {
        padding = 2,
        font_color = { 165, 165, 165 },
        font = 'heading-2',
        use_header_filler = false
    }
}

Public.default_pusher = {
    style = {
        top_margin = 0,
        bottom_margin = 0,
        left_margin = 0,
        right_margin = 0,
    }
}

-- on top of vanilla's frame_header_flow, which spaces the title bar like Factorio's own windows
Public.default_title_bar = {
    style = {
        vertical_align = 'center',
    }
}

-- the two widths of side panels (see Gui.add_panel)
Public.panel_width = {
    narrow = 400,
    wide = 470,
    -- the minimap's, for a panel players float under it (the production HUD)
    minimap = 256,
}

Public.default_dragger = {
    style = {
        vertically_stretchable = true,
        horizontally_stretchable = true,
        margin = 0
    }
}

return Public
