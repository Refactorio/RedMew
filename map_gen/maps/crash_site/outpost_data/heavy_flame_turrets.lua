local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_walls{
    ob.make_4_way {
        flame_turret = {callback = ob.refill_liquid_turret_callback, data = ob.light_oil_ammo},
        turret = {callback = ob.refill_turret_callback, data = ob.uranium_rounds_magazine_ammo},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'stone-wall'}},
        [6] = {entity = {name = 'stone-wall'}},
        [7] = {entity = {name = 'gun-turret', callback = 'turret', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [8] = {tile = 'refined-hazard-concrete-left'},
        [9] = {entity = {name = 'gun-turret', callback = 'turret', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [10] = {tile = 'refined-hazard-concrete-left'},
        [11] = {entity = {name = 'gun-turret', callback = 'turret', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [12] = {tile = 'refined-hazard-concrete-left'},
        [13] = {tile = 'refined-hazard-concrete-left'},
        [14] = {tile = 'refined-hazard-concrete-left'},
        [15] = {tile = 'refined-hazard-concrete-left'},
        [16] = {tile = 'refined-hazard-concrete-left'},
        [17] = {tile = 'refined-hazard-concrete-left'},
        [18] = {tile = 'refined-hazard-concrete-left'},
        [19] = {tile = 'refined-hazard-concrete-left'},
        [20] = {tile = 'refined-hazard-concrete-left'},
        [21] = {tile = 'refined-hazard-concrete-left'},
        [22] = {tile = 'refined-hazard-concrete-left'},
        [23] = {tile = 'refined-hazard-concrete-left'},
        [24] = {tile = 'refined-hazard-concrete-left'},
        [25] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [26] = {tile = 'refined-hazard-concrete-left'},
        [27] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [28] = {tile = 'refined-hazard-concrete-left'},
        [29] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [30] = {tile = 'refined-hazard-concrete-left'},
        [31] = {tile = 'refined-hazard-concrete-left'},
        [32] = {tile = 'refined-hazard-concrete-left'},
        [33] = {tile = 'refined-hazard-concrete-left'},
        [34] = {tile = 'refined-hazard-concrete-left'},
        [35] = {tile = 'refined-hazard-concrete-left'},
        [36] = {tile = 'refined-hazard-concrete-left'}
    },
    ob.make_4_way {
        flame_turret = {callback = ob.refill_liquid_turret_callback, data = ob.light_oil_ammo},
        turret = {callback = ob.refill_turret_callback, data = ob.uranium_rounds_magazine_ammo},
        wall = {callback = ob.wall_callback},
        [1] = {entity = {name = 'stone-wall', callback = 'wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'stone-wall'}},
        [6] = {entity = {name = 'stone-wall'}},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {entity = {name = 'stone-wall'}},
        [9] = {tile = 'refined-hazard-concrete-left'},
        [10] = {tile = 'refined-hazard-concrete-left'},
        [11] = {tile = 'refined-hazard-concrete-left'},
        [12] = {tile = 'refined-hazard-concrete-left'},
        [13] = {entity = {name = 'stone-wall'}},
        [14] = {entity = {name = 'stone-wall'}},
        [15] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [16] = {tile = 'refined-hazard-concrete-left'},
        [17] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [18] = {tile = 'refined-hazard-concrete-left'},
        [19] = {entity = {name = 'stone-wall'}},
        [20] = {entity = {name = 'stone-wall'}},
        [21] = {tile = 'refined-hazard-concrete-left'},
        [22] = {tile = 'refined-hazard-concrete-left'},
        [23] = {tile = 'refined-hazard-concrete-left'},
        [24] = {tile = 'refined-hazard-concrete-left'},
        [25] = {entity = {name = 'stone-wall'}},
        [26] = {tile = 'refined-hazard-concrete-left'},
        [27] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', direction = 6, offset = 2},
            tile = 'refined-hazard-concrete-left'
        },
        [28] = {tile = 'refined-hazard-concrete-left'},
        [29] = {entity = {name = 'gun-turret', callback = 'turret', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [30] = {tile = 'refined-hazard-concrete-left'},
        [31] = {entity = {name = 'stone-wall'}},
        [32] = {tile = 'refined-hazard-concrete-left'},
        [33] = {tile = 'refined-hazard-concrete-left'},
        [34] = {tile = 'refined-hazard-concrete-left'},
        [35] = {tile = 'refined-hazard-concrete-left'},
        [36] = {tile = 'refined-hazard-concrete-left'}
    },
    ob.make_4_way {
        flame_turret = {callback = ob.refill_liquid_turret_callback, data = ob.light_oil_ammo},
        turret = {callback = ob.refill_turret_callback, data = ob.uranium_rounds_magazine_ammo},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {tile = 'refined-hazard-concrete-left'},
        [4] = {tile = 'refined-hazard-concrete-left'},
        [5] = {tile = 'refined-hazard-concrete-left'},
        [6] = {tile = 'refined-hazard-concrete-left'},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {entity = {name = 'gun-turret', callback = 'turret', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [9] = {tile = 'refined-hazard-concrete-left'},
        [10] = {tile = 'refined-hazard-concrete-left'},
        [11] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', direction = 6, offset = 2},
            tile = 'refined-hazard-concrete-left'
        },
        [12] = {tile = 'refined-hazard-concrete-left'},
        [13] = {tile = 'refined-hazard-concrete-left'},
        [14] = {tile = 'refined-hazard-concrete-left'},
        [15] = {tile = 'refined-hazard-concrete-left'},
        [16] = {tile = 'refined-hazard-concrete-left'},
        [17] = {tile = 'refined-hazard-concrete-left'},
        [18] = {tile = 'refined-hazard-concrete-left'},
        [19] = {tile = 'refined-hazard-concrete-left'},
        [20] = {tile = 'refined-hazard-concrete-left'},
        [21] = {tile = 'refined-hazard-concrete-left'},
        [22] = {tile = 'refined-hazard-concrete-left'},
        [23] = {tile = 'refined-hazard-concrete-left'},
        [24] = {tile = 'refined-hazard-concrete-left'},
        [25] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [26] = {tile = 'refined-hazard-concrete-left'},
        [27] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [28] = {tile = 'refined-hazard-concrete-left'},
        [29] = {
            entity = {name = 'flamethrower-turret', callback = 'flame_turret', offset = 1},
            tile = 'refined-hazard-concrete-left'
        },
        [30] = {tile = 'refined-hazard-concrete-left'},
        [31] = {tile = 'refined-hazard-concrete-left'},
        [32] = {tile = 'refined-hazard-concrete-left'},
        [33] = {tile = 'refined-hazard-concrete-left'},
        [34] = {tile = 'refined-hazard-concrete-left'},
        [35] = {tile = 'refined-hazard-concrete-left'},
        [36] = {tile = 'refined-hazard-concrete-left'}
    }
}
