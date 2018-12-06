--[[
    -- Add correct requires here
    -- Add items and balance prices

    local item_market = {
    data = {
        {name = 'raw-wood', price = 1},
        {name = 'iron-plate', price = 2},
        {name = 'stone', price = 2},
        {name = 'coal', price = 1.25},
        {name = 'raw-fish', price = 4},
        {name = 'firearm-magazine', price = 5},
        {name = 'science-pack-1', price = 20},
        {name = 'science-pack-2', price = 40},
        {name = 'military-science-pack', price = 80},
        {name = 'science-pack-3', price = 120},
        {name = 'production-science-pack', price = 240},
        {name = 'high-tech-science-pack', price = 360},
        {name = 'small-plane', price = 100}
    }

    local creep_market = {
    data = {
        {name = 'small-biter', price = 1},
        {name = 'medium-biter', price = 1},
        {name = 'big-biter', price = 1},
        {name = 'behemoth-biter', price = 1},
        {name = 'small-spitter', price = 4},
        {name = 'medium-spitter', price = 5}
    }

    local tome_market = {
    data = {
        {name = 'kill-all', price = 1},
        {name = 'run-speed-increase', price = 1},
        {name = 'buff-biter', price = 1}
        {name = 'agro-stone', price = 1}    -- something that forces the biters to attack the holder. Possible?
        {name = 'furnace-health', price = 1} -- pre-emptive measure to upgrade the building health?
    }
}

]]--