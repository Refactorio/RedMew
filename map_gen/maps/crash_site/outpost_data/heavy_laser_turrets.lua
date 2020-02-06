local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_walls{
    ob.make_4_way {
        turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'stone-wall'}},
        [6] = {entity = {name = 'stone-wall'}},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {entity = {name = 'stone-wall'}},
        [9] = {entity = {name = 'stone-wall'}},
        [10] = {entity = {name = 'stone-wall'}},
        [11] = {entity = {name = 'stone-wall'}},
        [12] = {entity = {name = 'stone-wall'}},
        [13] = {
            entity = {name = 'laser-turret', callback = 'turret', offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [14] = {tile = 'refined-hazard-concrete-left'},
        [15] = {
            entity = {name = 'laser-turret', callback = 'turret', offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [16] = {tile = 'refined-hazard-concrete-left'},
        [17] = {
            entity = {name = 'laser-turret', callback = 'turret', offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [18] = {tile = 'refined-hazard-concrete-left'},
        [19] = {tile = 'refined-hazard-concrete-left'},
        [20] = {tile = 'refined-hazard-concrete-left'},
        [21] = {tile = 'refined-hazard-concrete-left'},
        [22] = {tile = 'refined-hazard-concrete-left'},
        [23] = {tile = 'refined-hazard-concrete-left'},
        [24] = {tile = 'refined-hazard-concrete-left'},
        [25] = {
            entity = {name = 'laser-turret', callback = 'turret', offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [26] = {tile = 'refined-hazard-concrete-left'},
        [27] = {entity = {name = 'substation', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [28] = {tile = 'refined-hazard-concrete-left'},
        [29] = {
            entity = {name = 'laser-turret', callback = 'turret', offset = 3},
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
        turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
        wall = {callback = ob.wall_callback},
        [1] = {entity = {name = 'stone-wall', callback = 'wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'stone-wall'}},
        [6] = {entity = {name = 'stone-wall'}},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {entity = {name = 'stone-wall'}},
        [9] = {entity = {name = 'stone-wall'}},
        [10] = {entity = {name = 'stone-wall'}},
        [11] = {entity = {name = 'stone-wall'}},
        [12] = {entity = {name = 'stone-wall'}},
        [13] = {entity = {name = 'stone-wall'}},
        [14] = {entity = {name = 'stone-wall'}},
        [15] = {
            entity = {name = 'laser-turret', callback = 'turret', offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [16] = {tile = 'refined-hazard-concrete-left'},
        [17] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
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
        [26] = {entity = {name = 'stone-wall'}},
        [27] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [28] = {tile = 'refined-hazard-concrete-left'},
        [29] = {entity = {name = 'substation', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [30] = {tile = 'refined-hazard-concrete-left'},
        [31] = {entity = {name = 'stone-wall'}},
        [32] = {entity = {name = 'stone-wall'}},
        [33] = {tile = 'refined-hazard-concrete-left'},
        [34] = {tile = 'refined-hazard-concrete-left'},
        [35] = {tile = 'refined-hazard-concrete-left'},
        [36] = {tile = 'refined-hazard-concrete-left'}
    },
    ob.make_4_way {
        turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [4] = {tile = 'refined-hazard-concrete-left'},
        [5] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [6] = {tile = 'refined-hazard-concrete-left'},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {entity = {name = 'stone-wall'}},
        [9] = {tile = 'refined-hazard-concrete-left'},
        [10] = {tile = 'refined-hazard-concrete-left'},
        [11] = {tile = 'refined-hazard-concrete-left'},
        [12] = {tile = 'refined-hazard-concrete-left'},
        [13] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [14] = {tile = 'refined-hazard-concrete-left'},
        [15] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [16] = {tile = 'refined-hazard-concrete-left'},
        [17] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [18] = {tile = 'refined-hazard-concrete-left'},
        [19] = {tile = 'refined-hazard-concrete-left'},
        [20] = {tile = 'refined-hazard-concrete-left'},
        [21] = {tile = 'refined-hazard-concrete-left'},
        [22] = {tile = 'refined-hazard-concrete-left'},
        [23] = {tile = 'refined-hazard-concrete-left'},
        [24] = {tile = 'refined-hazard-concrete-left'},
        [25] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [26] = {tile = 'refined-hazard-concrete-left'},
        [27] = {
            entity = {name = 'laser-turret', callback = 'turret', direction = 2, offset = 3},
            tile = 'refined-hazard-concrete-left'
        },
        [28] = {tile = 'refined-hazard-concrete-left'},
        [29] = {entity = {name = 'substation', offset = 3}, tile = 'refined-hazard-concrete-left'},
        [30] = {tile = 'refined-hazard-concrete-left'},
        [31] = {tile = 'refined-hazard-concrete-left'},
        [32] = {tile = 'refined-hazard-concrete-left'},
        [33] = {tile = 'refined-hazard-concrete-left'},
        [34] = {tile = 'refined-hazard-concrete-left'},
        [35] = {tile = 'refined-hazard-concrete-left'},
        [36] = {tile = 'refined-hazard-concrete-left'}
    }
}
