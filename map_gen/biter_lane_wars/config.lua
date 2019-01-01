-- Dependencies
local BLW = global.map.blw
local ScenarioInfo = require 'features.gui.info'


local Config = {
    features = {
        -- copied from diggy but useful here
        -- lets you set the coin modifiers for aliens
        -- the modifier value increases the upper random limit that biters can drop

        -- Needs configuring to work per team.
        alien_coin_modifiers = {
            ['small-biter'] = 2,
            ['small-spitter'] = 2,
            ['small-worm-turret'] = 2,
            ['medium-biter'] = 3,
            ['medium-spitter'] = 3,
            ['medium-worm-turret'] = 3,
            ['big-biter'] = 5,
            ['big-spitter'] = 5,
            ['big-worm-turret'] = 5,
            ['behemoth-biter'] = 7,
            ['behemoth-spitter'] = 7,
        },

        -- chance of aliens dropping coins between 0 and 1, where 1 is 100%
        alien_coin_drop_chance = 0.75,
--[[
        -- NEEDS CONFIGURING TO WORK PER TEAM

        -- spawns the following units when they die. To disable, remove the contents
        -- any non-rounded number will turn into a chance to spawn an additional alien
        -- example: 2.5 would spawn 2 for sure and 50% chance to spawn one additionally
        hail_hydra = {
            -- spitters
            ['small-spitter'] = {['small-worm-turret'] = 0.2},
            ['medium-spitter'] = {['medium-worm-turret'] = 0.2},
            ['big-spitter'] = {['big-worm-turret'] = 0.2},
            ['behemoth-spitter'] = {['big-worm-turret'] = 0.4},

            -- biters
            ['medium-biter'] = {['small-biter'] = 1.2},
            ['big-biter'] = {['medium-biter'] = 1.2},
            ['behemoth-biter'] = {['big-biter'] = 1.2},

            -- worms
            ['small-worm-turret'] = {['small-biter'] = 2.5},
            ['medium-worm-turret'] = {['small-biter'] = 2.5, ['medium-biter'] = 0.6},
            ['big-worm-turret'] = {['small-biter'] = 3.8, ['medium-biter'] = 1.3, ['big-biter'] = 1.1},
        },]]

    }


}

ScenarioInfo.set_map_name('Biter Lane Wars')
ScenarioInfo.set_map_description('Team lane defence map.')
ScenarioInfo.set_map_extra_info('- Send biters to your opponents using the market\n- Earn more gold per wave by sending more biters\n- Defend your smelter at all costs!')

--Config.



return Config
