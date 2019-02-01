local ob = require 'map_gen.maps.crash_site.outpost_builder'

return ob.make_1_way {
    part_size = 3,
    force = 'neutral',
    max_count = 2,
    [1] = {tile = 'stone-path'},
    [2] = {tile = 'stone-path'},
    [3] = {tile = 'stone-path'},
    [4] = {tile = 'stone-path'},
    [5] = {entity = {name = 'assembling-machine-3', callback = 'factory'}, tile = 'stone-path'},
    [6] = {tile = 'stone-path'},
    [7] = {tile = 'stone-path'},
    [8] = {tile = 'stone-path'},
    [9] = {tile = 'stone-path'}
}
