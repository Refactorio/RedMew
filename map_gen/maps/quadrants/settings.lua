local settings = {
    map = {
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
    },
    mapgen = {
        ores = {
            autoplace_controls = {
                coal = {
                    frequency = 2,
                    richness = 0.25,
                    size = 0.66
                },
                ['copper-ore'] = {
                    frequency = 4,
                    richness = 0.25,
                    size = 0.5
                },
                ['crude-oil'] = {
                    frequency = 0.5,
                    richness = 0.75,
                    size = 0.66
                },
                ['iron-ore'] = {
                    frequency = 4,
                    richness = 0.25,
                    size = 0.5
                },
                stone = {
                    frequency = 1,
                    richness = 0.25,
                    size = 0.5
                },
                ['uranium-ore'] = {
                    frequency = 0.5,
                    richness = 0.25,
                    size = 0.5
                }
            }
        },
        water = {
            terrain_segmentation = 0.5,
            water = 0.5
        },
        enemy = {
            autoplace_controls = {
                ['enemy-base'] = {
                    frequency = 2,
                    richness = 1.2,
                    size = 1.2
                }
            }
        }
    }
}

return settings
