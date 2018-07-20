local ob = require 'map_gen.presets.crash_site.outpost_builder'

return {
    ob.make_4_way {
        force = 'player',
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'stone-wall'}},
        [6] = {entity = {name = 'stone-wall'}}
    },
    ob.make_4_way {
        [1] = {entity = {name = 'stone-wall'}},
        [2] = {entity = {name = 'stone-wall'}},
        [3] = {entity = {name = 'stone-wall'}},
        [4] = {entity = {name = 'stone-wall'}},
        [5] = {entity = {name = 'stone-wall'}},
        [6] = {entity = {name = 'stone-wall'}},
        [7] = {entity = {name = 'stone-wall'}},
        [13] = {entity = {name = 'stone-wall'}},
        [19] = {entity = {name = 'stone-wall'}},
        [25] = {entity = {name = 'stone-wall'}},
        [31] = {entity = {name = 'stone-wall'}}
    },
    ob.make_4_way {
        [1] = {entity = {name = 'stone-wall'}}
    }
}
