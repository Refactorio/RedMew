return {
    -- ~7 minute cycle, 3m28s of full light, 1m23s light to dark, 42s full dark, 1m23s dark to light
    vanilla = {
        ticks_per_day = 25000,
        dusk = 0.25,
        evening = 0.45,
        morning = 0.55,
        dawn = 0.75
    },
    -- 10 minute cycle, 4m of full light, 4m light to dark, 6s full dark, 2m dark to light
    bright = {
        ticks_per_day = 36000,
        dusk = 0.2,
        evening = 0.59,
        morning = 0.6,
        dawn = 0.8
    },
    -- ~14 minute cycle, 6m56s of full light, 2m46s light to dark, 1m24s full dark, 2m46s dark to light
    double_length = {
        ticks_per_day = 50000,
        dusk = 0.25,
        evening = 0.45,
        morning = 0.55,
        dawn = 0.75
    },
    -- 10 minute cycle, 6s of full light, 2m light to dark, 4m full dark, 4m dark to light
    gloomy = {
        ticks_per_day = 36000,
        dusk = 0,
        evening = 0.2,
        morning = 0.6,
        dawn = 0.99
    },
    -- ~3.5 minute cycle, 1m44s of full light, 42s light to dark, 21s full dark, 42s dark to light
    half_length = {
        ticks_per_day = 12500,
        dusk = 0.25,
        evening = 0.45,
        morning = 0.55,
        dawn = 0.75
    },
    -- 20 minute cycle, 9m of full light, 1m light to dark, 9m full dark, 1m dark to light
    long_days_long_nights_fast_transitions = {
        ticks_per_day = 72000,
        dusk = 0.225,
        evening = 0.275,
        morning = 0.725,
        dawn = 0.775
    },
    -- 6 hour cycle based on Feb 3 London, England for the day/night/twilight times:
    -- Day: 2h15m Night: 2h45m Day to night and night to day: 30m each Map starts mid-day
    feb3 = {
        ticks_per_day = 1296000,
        dusk = 4.5 / 24,
        evening = 15.5 / 24,
        morning = 17.5 / 24,
        dawn = 19.5 / 24
    }
}
