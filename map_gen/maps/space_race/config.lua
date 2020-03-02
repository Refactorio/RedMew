local Config = {
    version = 'v0.4.7',
    players_needed_to_start_game = 4,
    bootstrap_period = 60 * 60 * 30, -- 30 minutes
    player_kill_reward = 25,
    entity_kill_rewards = {
        ['default'] = 1,
        ['wooden-chest'] = 0,
        ['gun-turret'] = 5,
        ['laser-turret'] = 10,
        ['flamethrower-turret'] = 8,
        ['artillery-turret'] = 50,
        ['artillery-wagon'] = 30,
        ['locomotive'] = 10,
        ['cargo-wagon'] = 5,
        ['fluid-wagon'] = 5,
        ['radar'] = 5
    },
    disabled_research = {
        ['military'] = {player = 2, entity = 8},
        ['military-2'] = {player = 6, entity = 24, unlocks = 'military'},
        ['military-3'] = {player = 12, entity = 48, unlocks = 'military-2'},
        ['military-4'] = {player = 24, entity = 96, unlocks = 'military-3'},
        ['stone-walls'] = {player = 2, entity = 8, invert = true},
        ['heavy-armor'] = {player = 12, entity = 48, invert = true},
        ['artillery-shell-range-1'] = nil
    },
    disabled_recipes = {
        'tank',
        'rocket-silo'
    },
    entity_drop_amount = {
        --NEEDS BALANCING!
        ['biter-spawner'] = {low = 2, high = 10, chance = 1},
        ['spitter-spawner'] = {low = 2, high = 10, chance = 1},
        ['small-worm-turret'] = {low = 2, high = 5, chance = 0.5},
        ['medium-worm-turret'] = {low = 5, high = 7, chance = 0.5},
        ['big-worm-turret'] = {low = 5, high = 10, chance = 0.5},
        ['behemoth-worm-turret'] = {low = 5, high = 15, chance = 0.4},
        -- default is 0, no chance of coins dropping from biters/spitters
        ['small-biter'] = {low = 1, high = 2, chance = 0.05},
        ['small-spitter'] = {low = 2, high = 3, chance = 0.05},
        ['medium-spitter'] = {low = 3, high = 6, chance = 0.05},
        ['big-spitter'] = {low = 5, high = 15, chance = 0.05},
        ['behemoth-spitter'] = {low = 20, high = 30, chance = 0.05},
        ['medium-biter'] = {low = 3, high = 5, chance = 0.05},
        ['big-biter'] = {low = 3, high = 8, chance = 0.05},
        ['behemoth-biter'] = {low = 8, high = 10, chance = 0.05}
    },
    turret_active_delays = {
        ['ammo-turret'] = 60 * 3,
        ['electric-turret'] = 60 * 10,
        ['fluid-turret'] = 60 * 5,
        ['artillery-turret'] = 60 * 60
    },
    warning_on_built = {
        ['artillery-turret'] = true,
        ['artillery-wagon'] = true,
        ['tank'] = true
    },
    neutral_entities = {
        ['wooden-chest'] = true
    },
    snake = {
        size = 45,
        max_food = 8,
        speed = 30
    },
    map_gen = { -- Does not yet support being changed!
        width_1 = 256,
        width_2 = 256,
        width_3 = 9
    },
    game_mode = {
        king_of_the_hill = true
    }
}

return Config
