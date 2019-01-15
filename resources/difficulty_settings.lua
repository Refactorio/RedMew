-- technology_difficulty has no effect in vanilla
return {
    -- the default table is included as a reference but also to give the option of overwriting all user settings
    default = {
        recipe_difficulty = defines.difficulty_settings.recipe_difficulty.normal,
        technology_difficulty = defines.difficulty_settings.technology_difficulty.normal,
        technology_price_multiplier = 1
    },
    -- turns on expensive recipes
    expensive_recipe = {
        recipe_difficulty = defines.difficulty_settings.recipe_difficulty.expensive
    },
    -- the following are tech cost reducers
    ['tech_x0.25'] = {
        technology_price_multiplier = 0.25
    },
    ['tech_x0.5'] = {
        technology_price_multiplier = 0.5
    },
    ['tech_x0.75'] = {
        technology_price_multiplier = 0.75
    },
    -- the following are all tech cost multipliers
    tech_x2 = {
        technology_price_multiplier = 2
    },
    tech_x3 = {
        technology_price_multiplier = 3
    },
    tech_x4 = {
        technology_price_multiplier = 4
    },
    tech_x5 = {
        technology_price_multiplier = 5
    },
    tech_x6 = {
        technology_price_multiplier = 6
    },
    tech_x8 = {
        technology_price_multiplier = 8
    },
    tech_x10 = {
        technology_price_multiplier = 10
    },
    tech_x12 = {
        technology_price_multiplier = 12
    },
    tech_x14 = {
        technology_price_multiplier = 14
    },
    tech_x16 = {
        technology_price_multiplier = 16
    },
    tech_x20 = {
        technology_price_multiplier = 20
    },
    tech_x50 = {
        technology_price_multiplier = 50
    },
    tech_x100 = {
        technology_price_multiplier = 100
    },
    tech_x250 = {
        technology_price_multiplier = 250
    },
    tech_x500 = {
        technology_price_multiplier = 500
    },
    tech_x1000 = {
        technology_price_multiplier = 1000
    }
}
