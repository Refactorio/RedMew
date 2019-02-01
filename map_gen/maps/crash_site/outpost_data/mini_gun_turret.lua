local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_walls {
    ob.make_4_way {
        part_size = 3,
        turret = {callback = ob.refill_turret_callback, data = ob.firearm_magazine_ammo},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {tile = 'concrete'},
        [5] = {entity = {name = 'gun-turret', offset = 3, callback = 'turret'}, tile = 'concrete'},
        [6] = {tile = 'concrete'},
        [7] = {tile = 'stone-path'},
        [8] = {tile = 'stone-path'},
        [9] = {tile = 'stone-path'}
    },
    ob.make_4_way {
        part_size = 3,
        turret = {callback = ob.refill_turret_callback, data = ob.firearm_magazine_ammo},
        wall = {callback = ob.wall_callback},
        [1] = {entity = {name = 'stone-wall', callback = 'wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'gun-turret', offset = 3, callback = 'turret'}, tile = 'concrete'},
        [6] = {tile = 'concrete'},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {tile = 'concrete'},
        [9] = {tile = 'stone-path'}
    },
    ob.make_4_way {
        part_size = 3,
        turret = {callback = ob.refill_turret_callback, data = ob.firearm_magazine_ammo},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {tile = 'concrete'},
        [3] = {tile = 'stone-path'},
        [4] = {tile = 'concrete'},
        [5] = {entity = {name = 'gun-turret', offset = 3, callback = 'turret'}, tile = 'concrete'},
        [6] = {tile = 'stone-path'},
        [7] = {tile = 'stone-path'},
        [8] = {tile = 'stone-path'},
        [9] = {tile = 'stone-path'}
    }
}
