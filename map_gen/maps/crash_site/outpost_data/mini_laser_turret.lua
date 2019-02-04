local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_walls {
    ob.make_4_way {
        part_size = 3,
        turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'hazard-concrete-left'},
        [5] = {tile = 'hazard-concrete-left'},
        [6] = {tile = 'hazard-concrete-left'},
        [7] = {tile = 'stone-path'},
        [8] = {tile = 'stone-path'},
        [9] = {entity = {name = 'medium-electric-pole'}, tile = 'stone-path'}
    },
    ob.make_4_way {
        part_size = 3,
        turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
        wall = {callback = ob.wall_callback},
        [1] = {entity = {name = 'stone-wall', callback = 'wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'hazard-concrete-left'},
        [6] = {tile = 'hazard-concrete-left'},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {tile = 'hazard-concrete-left'},
        [9] = {tile = 'stone-path'}
    },
    ob.make_4_way {
        part_size = 3,
        turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {tile = 'hazard-concrete-left'},
        [3] = {tile = 'stone-path'},
        [4] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'hazard-concrete-left'},
        [5] = {tile = 'hazard-concrete-left'},
        [6] = {tile = 'stone-path'},
        [7] = {tile = 'stone-path'},
        [8] = {tile = 'stone-path'},
        [9] = {entity = {name = 'medium-electric-pole'}, tile = 'stone-path'}
    }
}
