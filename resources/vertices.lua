local shapes = {
    arrow = {
        --triangle
        {1, 1}, -- right edge g
        {-1, 1}, -- left edge b
        {0, 0}, -- top (pointer) a
        --rectangle
        {0.5, 1}, -- right inner top  f
        {0.5, 2}, -- right inner bottom e
        {-0.5, 1}, -- left inner top c
        {-0.5, 2} -- left inner bottom d
    }
}

return shapes
