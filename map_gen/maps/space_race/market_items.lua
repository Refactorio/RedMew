return {
    {
        name = 'stone-walls',
        name_label = {'', 'Stone Walls research'},
        type = 'research',
        description = {'', 'Unlocks stone walls research'},
        sprite = 'technology/stone-walls',
        stack_limit = 1,
        price = 250,
        disabled = true,
        disabled_reason = {'', 'DISABLED'}
    },
    {
        name = 'heavy-armor',
        name_label = {'', 'Heavy Armor research'},
        type = 'research',
        description = {'', 'Unlocks heavy armor research'},
        sprite = 'technology/heavy-armor',
        stack_limit = 1,
        price = 400,
        disabled = true,
        disabled_reason = {'', 'DISABLED'}
    },
    {
        name = 'military',
        name_label = {'', 'Military 1 research'},
        type = 'research',
        description = {'', 'Unlocks military research'},
        sprite = 'technology/military',
        stack_limit = 1,
        price = 100,
        disabled = true,
        disabled_reason = {'', 'DISABLED'}
    },
    {
        name = 'military-2',
        name_label = {'', 'Military 2 research'},
        type = 'research',
        description = {'', 'Unlocks military 2 research'},
        sprite = 'technology/military-2',
        stack_limit = 1,
        price = 1000,
        disabled = true,
        disabled_reason = {'', 'DISABLED'}
    },
    {
        name = 'military-3',
        name_label = {'', 'Military 3 research'},
        type = 'research',
        description = {'', 'Unlocks military 3 research'},
        sprite = 'technology/military-3',
        stack_limit = 1,
        price = 10000,
        disabled = true,
        disabled_reason = {'', 'DISABLED'}
    },
    {
        name = 'military-4',
        name_label = {'', 'Military 4 research'},
        type = 'research',
        description = {'', 'Unlocks military 4 research'},
        sprite = 'technology/military-3',
        stack_limit = 1,
        price = 10000,
        disabled = true,
        disabled_reason = {'', 'DISABLED'}
    },
    {price = 2, name = 'raw-fish'},
    {price = 200, name = 'tank', disabled = true, disabled_reason = {'', 'DISABLED'}}
}

--[[
The retailer can only register the same item once, meaning that you can't disable for one force but enable for the other
You'll need two market_items one with a prefix for the one force, and one with the prefix for the other force
For ITEMS you need to award the item through the on_market_purchase event.
]]
