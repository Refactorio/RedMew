local ob = require 'map_gen.presets.crash_site.outpost_builder'

return {
    ob.make_1_way {
        force = 'neutral',
        factory = {
            callback = ob.magic_item_crafting_callback,
            data = {
                recipe = 'basic-oil-processing',
                output = {
                    {item = 'petroleum-gas',fluidbox_index = 1,  min_rate = 4 / 60, distance_factor = 4 / 60 / 100},
                    {item = 'light-oil',fluidbox_index = 2, min_rate = 3 / 60, distance_factor = 3 / 60 / 100},
                    {item = 'heavy-oil',fluidbox_index = 3, min_rate = 3 / 60, distance_factor = 3 / 60 / 100}
                }
            }
        },
        [15] = {entity = {name = 'oil-refinery', callback = 'factory'}}
    }
}
