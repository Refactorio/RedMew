local settings = {
    enemy_debuff = {
        enemy_evolution = {
            enabled = true,
            time_factor = 0.000002,
            destroy_factor = 0.001,
            pollution_factor = 0.0000006
        },
        enemy_expansion = {
            enabled = true,
            max_expansion_distance = 5,
            settler_group_min_size = 5,
            settler_group_max_size = 20,
            min_expansion_cooldown = 10 * 3600,
            max_expansion_cooldown = 90 * 3600
        }
    }
}

return settings
