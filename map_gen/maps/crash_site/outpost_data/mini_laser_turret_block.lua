local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_1_way {
    part_size = 3,
    turret = {callback = ob.power_source_callback, data = ob.laser_turrent_power_source},
    max_count = 2,
    [1] = {tile = 'hazard-concrete-left'},
    [2] = {tile = 'hazard-concrete-left'},
    [3] = {tile = 'hazard-concrete-left'},
    [4] = {tile = 'hazard-concrete-left'},
    [5] = {entity = {name = 'laser-turret', callback = 'turret', offset = 3}, tile = 'hazard-concrete-left'},
    [6] = {entity = {name = 'medium-electric-pole'}, tile = 'hazard-concrete-left'},
    [7] = {tile = 'hazard-concrete-left'},
    [8] = {tile = 'hazard-concrete-left'},
    [9] = {tile = 'hazard-concrete-left'}
}
