local ob = require 'map_gen.presets.crash_site.outpost_builder'

return {
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
        [21] = {
            entity = {
                name = 'laser-turret',
                offset = 3,
                callback = 'turret'
            }
        },
        [33] = {entity = {name = 'medium-electric-pole'}}
    },
    ob.make_4_way {
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
        [13] = {entity = {name = 'stone-wall'}},
        [14] = {entity = {name = 'stone-wall'}},
        [19] = {entity = {name = 'stone-wall'}},
        [20] = {entity = {name = 'stone-wall'}},
        [22] = {entity = {name = 'laser-turret', offset = 3}},
        [25] = {entity = {name = 'stone-wall'}},
        [26] = {entity = {name = 'stone-wall'}},
        [31] = {entity = {name = 'stone-wall'}},
        [32] = {entity = {name = 'stone-wall'}},
        [36] = {entity = {name = 'medium-electric-pole'}}
    },
    ob.make_4_way {
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {entity = {name = 'stone-wall'}},
        [22] = {entity = {name = 'laser-turret', offset = 3}},
        [36] = {entity = {name = 'medium-electric-pole'}}
    }
}
