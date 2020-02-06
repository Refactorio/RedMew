local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_walls {
    ob.make_4_way {
        part_size = 3,
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {tile = 'concrete'},
        [5] = {tile = 'concrete'},
        [6] = {tile = 'concrete'},
        [7] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'},
        [8] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'},
        [9] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'}
    },
    ob.make_4_way {
        part_size = 3,
        wall = {callback = ob.wall_callback},
        [1] = {entity = {name = 'stone-wall', callback = 'wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {tile = 'concrete'},
        [6] = {tile = 'concrete'},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {tile = 'concrete'},
        [9] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'}
    },
    ob.make_4_way {
        part_size = 3,
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {tile = 'concrete'},
        [3] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'},
        [4] = {tile = 'concrete'},
        [5] = {tile = 'concrete'},
        [6] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'},
        [7] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'},
        [8] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'},
        [9] = {entity = {name = 'iron-chest', force = 'neutral', callback = 'loot'}, tile = 'stone-path'}
    }
}
