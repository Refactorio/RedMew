local ob = require 'map_gen.presets.crash_site.outpost_builder'

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
        [13] = {tile = 'hazard-concrete-left'},
        [14] = {tile = 'concrete'},
        [15] = {tile = 'hazard-concrete-left'},
        [16] = {tile = 'concrete'},
        [17] = {tile = 'hazard-concrete-left'},
        [18] = {tile = 'concrete'},
        [19] = {tile = 'hazard-concrete-left'},
        [20] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'concrete'},
        [21] = {tile = 'hazard-concrete-left'},
        [22] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'concrete'},
        [23] = {tile = 'hazard-concrete-left'},
        [24] = {tile = 'concrete'},
        [25] = {tile = 'hazard-concrete-left'},
        [26] = {tile = 'concrete'},
        [27] = {tile = 'hazard-concrete-left'},
        [28] = {tile = 'concrete'},
        [29] = {tile = 'hazard-concrete-left'},
        [30] = {tile = 'concrete'},
        [31] = {tile = 'hazard-concrete-left'},
        [32] = {tile = 'concrete'},
        [33] = {entity = {name = 'medium-electric-pole'}, tile = 'hazard-concrete-left'},
        [34] = {entity = {name = 'medium-electric-pole'}, tile = 'concrete'},
        [35] = {tile = 'hazard-concrete-left'},
        [36] = {tile = 'concrete'}
    },
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
        [13] = {entity = {name = 'stone-wall'}},
        [14] = {entity = {name = 'stone-wall'}},
        [15] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'concrete'},
        [16] = {tile = 'hazard-concrete-left'},
        [17] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'concrete'},
        [18] = {tile = 'hazard-concrete-left'},
        [19] = {entity = {name = 'stone-wall'}},
        [20] = {entity = {name = 'stone-wall'}},
        [21] = {tile = 'hazard-concrete-left'},
        [22] = {tile = 'concrete'},
        [23] = {tile = 'hazard-concrete-left'},
        [24] = {tile = 'concrete'},
        [25] = {entity = {name = 'stone-wall'}},
        [26] = {entity = {name = 'stone-wall'}},
        [27] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'concrete'},
        [28] = {tile = 'hazard-concrete-left'},
        [29] = {entity = {name = 'medium-electric-pole'}, tile = 'concrete'},
        [30] = {tile = 'hazard-concrete-left'},
        [31] = {entity = {name = 'stone-wall'}},
        [32] = {entity = {name = 'stone-wall'}},
        [33] = {tile = 'hazard-concrete-left'},
        [34] = {tile = 'concrete'},
        [35] = {tile = 'hazard-concrete-left'},
        [36] = {entity = {name = 'medium-electric-pole'}, tile = 'concrete'}
    },
    ob.make_4_way {
        turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {tile = 'concrete'},
        [4] = {tile = 'hazard-concrete-left'},
        [5] = {tile = 'concrete'},
        [6] = {tile = 'hazard-concrete-left'},
        [7] = {entity = {name = 'stone-wall'}},
        [8] = {entity = {name = 'stone-wall'}},
        [9] = {tile = 'hazard-concrete-left'},
        [10] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'concrete'},
        [11] = {tile = 'hazard-concrete-left'},
        [12] = {tile = 'concrete'},
        [13] = {tile = 'concrete'},
        [14] = {tile = 'hazard-concrete-left'},
        [15] = {tile = 'concrete'},
        [16] = {tile = 'hazard-concrete-left'},
        [17] = {tile = 'concrete'},
        [18] = {tile = 'hazard-concrete-left'},
        [19] = {tile = 'hazard-concrete-left'},
        [20] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'concrete'},
        [21] = {tile = 'hazard-concrete-left'},
        [22] = {tile = 'concrete'},
        [23] = {tile = 'hazard-concrete-left'},
        [24] = {tile = 'concrete'},
        [25] = {tile = 'concrete'},
        [26] = {tile = 'hazard-concrete-left'},
        [27] = {tile = 'concrete'},
        [28] = {tile = 'hazard-concrete-left'},
        [29] = {tile = 'concrete'},
        [30] = {entity = {name = 'medium-electric-pole'}, tile = 'hazard-concrete-left'},
        [31] = {tile = 'hazard-concrete-left'},
        [32] = {tile = 'concrete'},
        [33] = {tile = 'hazard-concrete-left'},
        [34] = {tile = 'concrete'},
        [35] = {entity = {name = 'medium-electric-pole'}, tile = 'hazard-concrete-left'},
        [36] = {tile = 'concrete'}
    }
}