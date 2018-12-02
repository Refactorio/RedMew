-- vanilla day/night cycle, mostly just here as reference
-- ~7 minute cycle, 3m28s of full light, 1m23s light to dark, 42s full dark, 1m23s dark to light
local day_night_cycle = {
    ['ticks_per_day'] = 25000,
    ['dusk'] = 0.25,
    ['evening'] = 0.45,
    ['morning'] = 0.55,
    ['dawn'] = 0.75
}
return day_night_cycle
