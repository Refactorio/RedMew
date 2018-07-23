local ob = require 'map_gen.presets.crash_site.outpost_builder'

return {
    ob.make_1_way {
        force = 'neutral',
        factory = {
            callback = ob.magic_item_crafting_callback,
            data = {
                output = {min_rate = 1 / 60, distance_factor = 1 / 60 / 100, item = 'iron-plate'}
            }
        },
        [15] = {entity = {name = 'electric-furnace', callback = 'factory'}}
    }
}
