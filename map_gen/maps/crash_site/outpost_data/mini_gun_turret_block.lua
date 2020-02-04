local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_1_way {
    part_size = 3,
    turret = {callback = ob.refill_turret_callback, data = ob.firearm_magazine_ammo},
    max_count = 2,
    [1] = {tile = 'stone-path'},
    [2] = {tile = 'stone-path'},
    [3] = {tile = 'stone-path'},
    [4] = {tile = 'stone-path'},
    [5] = {entity = {name = 'gun-turret', offset = 3, callback = 'turret'}, tile = 'stone-path'},
    [6] = {tile = 'stone-path'},
    [7] = {tile = 'stone-path'},
    [8] = {tile = 'stone-path'},
    [9] = {tile = 'stone-path'}
}
